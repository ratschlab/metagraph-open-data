#!/usr/bin/env bash
set -euo pipefail

# ---------- Defaults (edit these, not the runtime vars below) ----------
DEFAULT_STACK_NAME="MetagraphQuerySystem"
DEFAULT_REGION="${AWS_REGION:-eu-west-1}"

# Common inputs for the collector
DEFAULT_INDEX_PREFIX="all_sra/data/metagenome"
DEFAULT_INDEX_FILTER=".*"
DEFAULT_GRAPH_SUFFIX="small.dbg"
DEFAULT_ANNO_SUFFIX="brwt.annodbg"
DEFAULT_QUERY_FILENAME=""
DEFAULT_JOB_ID=""
DEFAULT_MERGE="true"

# Command selection
DEFAULT_CMD="query"                    # query | align

# Query-mode params (only for CMD=query)
DEFAULT_QUERY_MODE="labels"            # labels | matches
DEFAULT_NUM_TOP_LABELS="inf"
DEFAULT_MIN_KMERS_FRACTION_LABEL="0.7"
DEFAULT_MIN_KMERS_FRACTION_GRAPH="0.0"

# Align-mode params (only for CMD=align)
DEFAULT_ALIGN_MIN_SEED_LENGTH="27"
DEFAULT_ALIGN_MIN_EXACT_MATCH="0.85"

# Batch/job extras (shared)
DEFAULT_TIME=""                        # set non-empty to enable /usr/bin/time -v
DEFAULT_BATCH_SIZE="$((8*10**6))"
DEFAULT_PROC="\$(nproc)"
DEFAULT_EXTRA_ARGS=""

# ---------- Runtime variables (initialized from defaults) ----------
STACK_NAME="$DEFAULT_STACK_NAME"
REGION="$DEFAULT_REGION"
INPUT_FILE=""
INTERACTIVE=false

INDEX_PREFIX="$DEFAULT_INDEX_PREFIX"
INDEX_FILTER="$DEFAULT_INDEX_FILTER"
GRAPH_SUFFIX="$DEFAULT_GRAPH_SUFFIX"
ANNO_SUFFIX="$DEFAULT_ANNO_SUFFIX"
QUERY_FILENAME="$DEFAULT_QUERY_FILENAME"
JOB_ID="$DEFAULT_JOB_ID"
MERGE="$DEFAULT_MERGE"

CMD="$DEFAULT_CMD"

QUERY_MODE="$DEFAULT_QUERY_MODE"
NUM_TOP_LABELS="$DEFAULT_NUM_TOP_LABELS"
MIN_KMERS_FRACTION_LABEL="$DEFAULT_MIN_KMERS_FRACTION_LABEL"
MIN_KMERS_FRACTION_GRAPH="$DEFAULT_MIN_KMERS_FRACTION_GRAPH"

ALIGN_MIN_SEED_LENGTH="$DEFAULT_ALIGN_MIN_SEED_LENGTH"
ALIGN_MIN_EXACT_MATCH="$DEFAULT_ALIGN_MIN_EXACT_MATCH"

TIME="$DEFAULT_TIME"
BATCH_SIZE="$DEFAULT_BATCH_SIZE"
PROC="$DEFAULT_PROC"
EXTRA_ARGS="$DEFAULT_EXTRA_ARGS"

# ---------- Helpers ----------
print_usage() {
  cat <<EOF
Usage: $0 [options]

Stack/region:
  --stack <name>           (default: ${DEFAULT_STACK_NAME})
  --region <aws-region>    (default: ${DEFAULT_REGION})

Input:
  --input-file <file.json> Provide raw JSON input instead of CLI params
  --interactive            Prompt for missing/optional parameters

Core (collector) params:
  --index-prefix <s3prefix>   (default: "${DEFAULT_INDEX_PREFIX}")
  --index-filter <regex>      (default: "${DEFAULT_INDEX_FILTER}")
  --graph-suffix <name>       (default: "${DEFAULT_GRAPH_SUFFIX}")
  --anno-suffix <name>        (default: "${DEFAULT_ANNO_SUFFIX}")
  --query-filename <file>     (required; under 'queries/'; default: "${DEFAULT_QUERY_FILENAME}")
  --job-id <id>               (default: auto if empty)
  --merge true|false          (default: ${DEFAULT_MERGE})

Command selection:
  --cmd query|align           (default: ${DEFAULT_CMD})

Params for --cmd query:
  --query-mode labels|matches         (default: ${DEFAULT_QUERY_MODE})
  --num-top-labels <N|inf>            (default: ${DEFAULT_NUM_TOP_LABELS})
  --min-kmers-fraction-label <float>  (default: ${DEFAULT_MIN_KMERS_FRACTION_LABEL})
  --min-kmers-fraction-graph <float>  (default: ${DEFAULT_MIN_KMERS_FRACTION_GRAPH})

Params for --cmd align:
  --align-min-seed-length <int>       (default: ${DEFAULT_ALIGN_MIN_SEED_LENGTH})
  --align-min-exact-match <float>     (default: ${DEFAULT_ALIGN_MIN_EXACT_MATCH})

Batch/job extras (shared):
  --time <any>                (default: "${DEFAULT_TIME}" -> disabled if empty)
  --batch-size <int>          (default: ${DEFAULT_BATCH_SIZE})
  --proc <value>              (default: ${DEFAULT_PROC})
  --extra-args "<args>"       (default: "${DEFAULT_EXTRA_ARGS}")

Examples:
  $0 --index-prefix all_sra/... --query-filename reads.fq --merge true
  $0 --cmd align --index-prefix ... --query-filename reads.fq --align-min-exact-match 0.9
EOF
}

prompt() {  # prompt "label" current_value -> echoes updated value
  local label="$1"; local current="$2"
  read -rp "${label} [${current}]: " _reply
  echo "${_reply:-$current}"
}

# ---------- Parse args ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --stack) STACK_NAME="$2"; shift 2;;
    --region) REGION="$2"; shift 2;;
    --input-file) INPUT_FILE="$2"; shift 2;;
    --interactive) INTERACTIVE=true; shift;;

    --index-prefix) INDEX_PREFIX="$2"; shift 2;;
    --index-filter) INDEX_FILTER="$2"; shift 2;;
    --graph-suffix) GRAPH_SUFFIX="$2"; shift 2;;
    --anno-suffix) ANNO_SUFFIX="$2"; shift 2;;
    --query-filename) QUERY_FILENAME="$2"; shift 2;;
    --job-id) JOB_ID="$2"; shift 2;;
    --merge) MERGE="$2"; shift 2;;

    --cmd) CMD="$2"; shift 2;;

    --query-mode) QUERY_MODE="$2"; shift 2;;
    --num-top-labels) NUM_TOP_LABELS="$2"; shift 2;;
    --min-kmers-fraction-label) MIN_KMERS_FRACTION_LABEL="$2"; shift 2;;
    --min-kmers-fraction-graph) MIN_KMERS_FRACTION_GRAPH="$2"; shift 2;;

    --align-min-seed-length) ALIGN_MIN_SEED_LENGTH="$2"; shift 2;;
    --align-min-exact-match) ALIGN_MIN_EXACT_MATCH="$2"; shift 2;;

    --time) TIME="${2:-1}"; shift 1;;  # allows --time or --time VALUE
    --batch-size) BATCH_SIZE="$2"; shift 2;;
    --proc) PROC="$2"; shift 2;;
    --extra-args) EXTRA_ARGS="$2"; shift 2;;

    -h|--help) print_usage; exit 0;;
    *) echo "Unknown arg: $1"; print_usage; exit 1;;
  esac
done

# ---------- Resolve state machine ARN ----------
STATE_MACHINE_ARN=$(aws cloudformation describe-stacks \
  --region "$REGION" \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='QueryStateMachineArn'].OutputValue | [0]" \
  --output text)

if [[ -z "$STATE_MACHINE_ARN" || "$STATE_MACHINE_ARN" == "None" ]]; then
  echo "Could not resolve QueryStateMachineArn from stack '$STACK_NAME' in region '$REGION'." >&2
  exit 1
fi

# ---------- If input file supplied, use it verbatim ----------
if [[ -n "$INPUT_FILE" ]]; then
  [[ -f "$INPUT_FILE" ]] || { echo "Input file '$INPUT_FILE' not found." >&2; exit 1; }
  echo "Starting execution with file: $INPUT_FILE"
  aws stepfunctions start-execution \
    --region "$REGION" \
    --state-machine-arn "$STATE_MACHINE_ARN" \
    --input "file://$INPUT_FILE"
  exit 0
fi

# ---------- Interactive prompts (only relevant fields) ----------
if $INTERACTIVE; then
  INDEX_PREFIX=$(prompt "index_prefix" "$INDEX_PREFIX")
  QUERY_FILENAME=$(prompt "query_filename (required; under 'queries/')" "$QUERY_FILENAME")
  MERGE=$(prompt "merge true|false" "$MERGE")
  JOB_ID=$(prompt "job_id (blank = auto)" "$JOB_ID")
  CMD=$(prompt "cmd query|align" "$CMD")

  # shared extras
  BATCH_SIZE=$(prompt "batch_size" "$BATCH_SIZE")
  PROC=$(prompt "proc" "$PROC")
  EXTRA_ARGS=$(prompt "extra_args (quoted string)" "$EXTRA_ARGS")
  TIME=$(prompt "enable /usr/bin/time? empty=no, any value=yes" "$TIME")

  # general filters/suffixes
  INDEX_FILTER=$(prompt "index_filter" "$INDEX_FILTER")
  GRAPH_SUFFIX=$(prompt "graph_suffix" "$GRAPH_SUFFIX")
  ANNO_SUFFIX=$(prompt "anno_suffix" "$ANNO_SUFFIX")

  if [[ "$CMD" == "query" ]]; then
    QUERY_MODE=$(prompt "query_mode labels|matches" "$QUERY_MODE")
    NUM_TOP_LABELS=$(prompt "num_top_labels <N|inf>" "$NUM_TOP_LABELS")
    MIN_KMERS_FRACTION_LABEL=$(prompt "min_kmers_fraction_label <float>" "$MIN_KMERS_FRACTION_LABEL")
    MIN_KMERS_FRACTION_GRAPH=$(prompt "min_kmers_fraction_graph <float>" "$MIN_KMERS_FRACTION_GRAPH")
  elif [[ "$CMD" == "align" ]]; then
    ALIGN_MIN_SEED_LENGTH=$(prompt "align_min_seed_length <int>" "$ALIGN_MIN_SEED_LENGTH")
    ALIGN_MIN_EXACT_MATCH=$(prompt "align_min_exact_match <float>" "$ALIGN_MIN_EXACT_MATCH")
  else
    echo "Invalid cmd: $CMD (must be 'query' or 'align')" >&2
    exit 1
  fi
fi

# ---------- Validate required ----------
if [[ -z "$QUERY_FILENAME" ]]; then
  echo "Missing required: --query-filename (or use --interactive)." >&2
  exit 1
fi

# ---------- Generate job id if empty ----------
if [[ -z "$JOB_ID" ]]; then
  JOB_ID="cli-$(date +%Y%m%d-%H%M%S)"
fi

# ---------- Build input JSON ----------
# We include only the cmd-relevant knobs.
if [[ "$CMD" == "query" ]]; then
  INPUT_JSON=$(cat <<JSON
{
  "index_prefix": "${INDEX_PREFIX}",
  "index_filter": "${INDEX_FILTER}",
  "graph_suffix": "${GRAPH_SUFFIX}",
  "anno_suffix": "${ANNO_SUFFIX}",

  "query_mode": "${QUERY_MODE}",
  "num_top_labels": "${NUM_TOP_LABELS}",
  "min_kmers_fraction_label": ${MIN_KMERS_FRACTION_LABEL},
  "min_kmers_fraction_graph": ${MIN_KMERS_FRACTION_GRAPH},

  "query_filename": "${QUERY_FILENAME}",
  "job_id": "${JOB_ID}",
  "merge": ${MERGE},

  "time": "${TIME}",
  "cmd": "${CMD}",
  "batch_size": ${BATCH_SIZE},
  "proc": "${PROC}",
  "extra_args": "${EXTRA_ARGS}"
}
JSON
)
else # align
  INPUT_JSON=$(cat <<JSON
{
  "index_prefix": "${INDEX_PREFIX}",
  "index_filter": "${INDEX_FILTER}",
  "graph_suffix": "${GRAPH_SUFFIX}",
  "anno_suffix": "${ANNO_SUFFIX}",

  "query_filename": "${QUERY_FILENAME}",
  "job_id": "${JOB_ID}",
  "merge": ${MERGE},

  "time": "${TIME}",
  "cmd": "${CMD}",
  "batch_size": ${BATCH_SIZE},
  "proc": "${PROC}",
  "extra_args": "${EXTRA_ARGS}",

  "align_min_seed_length": ${ALIGN_MIN_SEED_LENGTH},
  "align_min_exact_match": ${ALIGN_MIN_EXACT_MATCH}
}
JSON
)
fi

# ---------- Show + execute ----------
echo "Using state machine: $STATE_MACHINE_ARN"
echo "Composed input:"
echo "$INPUT_JSON" | sed 's/^/  /'

aws stepfunctions start-execution \
  --region "$REGION" \
  --state-machine-arn "$STATE_MACHINE_ARN" \
  --input "$INPUT_JSON"
