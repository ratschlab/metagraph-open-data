# MetaGraph Sequence Indexes
![global MetaGraph sequence search](img/github_header.jpg)

## Overview 
The MetaGraph Sequence Index dataset offers full-text searchable index files for raw sequencing data hosted in major public repositories. These include the European Nucleotide Archive (ENA) managed by the European Bioinformatics Institute (EMBL-EBI), the Sequence Read Archive (SRA) maintained by the National Center for Biotechnology Information (NCBI), and the DNA Data Bank of Japan (DDBJ) Sequence Read Archive (DRA). 
Currently, the index supports searches across more than 10 million individual samples, with this number steadily increasing as indexing efforts continue.

## Data

### Summary
This resources comprises MetaGraph index files that have been constructed from publicly available input data gathered from a variety of sources over the past years. Please see Data sources below for a more detailed description. 

## Data Sources (Overview)
* [Logan Contig Subset](#logan-contig-subset)
* [SRA High-level Subsets](#sra-high-level-subsets)
* [SRA MetaGut](#sra-metagut)
* [SRA Microbe](#sra-microbe)
* [RefSeq](#refseq)
* [Unified Human Gastrointestinal Genome](#unified-human-gastrointestinal-genome)

### Logan Contig Subset
These indexes use pre-assembled contigs from the [Logan](https://github.com/IndexThePlanet/Logan) project as input. For this pre-assembly singleton k-mers have been dropped and the assembly graph has been mildly cleaned.  

#### Organisation
Following the principle of phylogenetic compression, we have hierarchically clustered all samples using information from their biological taxonomy (as far as available). As a result, we currently have a pool of approximately 5,000 individual index chunks. Each of these chunks contains the information of a subset of the samples. Every chunk is assigned into one taxonomic categories. Overall, there are approx 200 taxonomic categories available, each containing only a few up to over 1,000 individual index chunks. The number of chunks within the same category is mostly driven by the number of samples available from that taxonomic group. The chunk size is limited for practical reasons, to allow for parallel construction and querying.

#### Available categories
Individual categories were formed by grouping phylogenetically similar samples together. This grouping started at the species level of the taxonomic tree. If too few samples were available to form a chunk, the taxonomic parent was selected for aggregation for samples. The resulting list of categories is available [here](https://github.com/ratschlab/metagraph-open-data/blob/main/data/categories_available.tsv).

#### Dataset layout
All data is available under the following root: [s3://metagraph/all_sra](https://metagraph.s3.amazonaws.com/index.html#all_sra/)

```
s3://metagraph/all_sra
+-- data
|   +-- category_A
|   |   +-- chunk_1
|   |   +-- ...
|   +-- ...
+-- metadata
    +-- category_A
    |   +-- chunk_1
    |   +-- ...
    +-- ...
```
Where `category_A` would be one of the [Available categories](#available-categories) mentioned above. Likewise, `chunk_1` would be replaced with a running number of the chunk, padded with zeros up to a total length of 4. 

As an example, to reach the data for the 10th chunk of the `metagenome` category, the resulting path would be `s3://metagraph/all_sra/data/metagenome/0010/`.

#### Chunk structure
Irrespective of whether you are in the `data` or the `metadata` branch, each chunk contains a standardized set of files. 

In the `data` branch one chunk contains:
```
annotation.clean.row_diff_brwt.annodbg
annotation.clean.row_diff_brwt.annodbg.md5
graph.primary.small.dbg
graph.primary.small.dbg.md5
```

Both files ending with `dbg` are needed for a full-text query. They form the MetaGraph index. The files ending in `md5` are check sums to verify correct transfer of data in case you download it.

In the `metadata` branch one chunk contains:
```
metadata.tsv.gz
```
This is a gzip-compress, human readable text file containing additional information about the samples that are contained within each index chunk.

### SRA High-level Subsets
These data sets contain indexes that are formed from grouping together SRA samples based on high-level taxonomic groups, prioritizing DNA whole genome sequencing (WGS) samples. The samples were selected using metadata queried via NCBI SRA’s BigQuery interface and underwent a cleaning pipeline to ensure data quality. The samples exclude sequencing data from long-read technologies like PacBio and Oxford Nanopore.

#### Organisation
Specifically, the following groups were formed:
* fungi
* human
* metazoa (excluding human)
* plants

#### Dataset layout
Each group has its data available at a dedicated S3 path (e.g., [s3://metagraph/fungi](https://metagraph.s3.amazonaws.com/index.html#fungi/)). Each dataset includes the graph file and the annotation file required for MetaGraph querying. MD5 checksums are provided for data integrity validation.

Example directory structure for `fungi`:
```
s3://metagraph/fungi
+-- annotation.relaxed.relabeled.row_diff_brwt.annodbg
+-- annotation.relaxed.relabeled.row_diff_brwt.annodbg.md5
+-- graph_primary_small.dbg
+-- graph_primary_small.dbg.md5
```

Please note that the `metazoa` and `human` have been split into chunks for simplified processing. The `metazoa` data is available as 17 separate chunks, each containing a specific graph and annotation file that need to be combined for query. The `human` data consists of a joint human graph as well as 11 separate annotation parts that can be sequentially used to retrieve different label sets.

#### Sample Statistics
* **Fungi** (NCBI TaxID: 4751):
  125,585 samples processed; 114,839 (91.4%) successfully cleaned.
* **Plants** (Viridiplantae; TaxID: 33090):
  576,226 samples processed; 531,736 (92.3%) successfully cleaned.
* **Human** (Homo sapiens; TaxID: 9606):
  454,252 samples processed; 436,502 (96.1%) successfully cleaned.
  Included assay types: WGS, AMPLICON, WXS, WGA, WCS, CLONE, POOLCLONE, FINISHING.
* **Metazoa** (excluding human; TaxID: 33208):
  906,401 samples processed; 805,239 (88.8%) successfully cleaned.

### SRA-Microbe
This subset replicates the original sample collection used in the BIGSI project. Though the data is outdated relative to the current SRA, it provides a valuable benchmark due to its historical significance.

#### Dataset layout
The data is available at [s3://metagraph/microbe](https://metagraph.s3.amazonaws.com/index.html#microbe/) and has the following layout, containing both the graph as well as annotation files and the respective checksums for integrity checks:
```
s3://metagraph/microbe
+-- annotation.relaxed.relabeled.row_diff_brwt.annodbg
+-- annotation.relaxed.relabeled.row_diff_brwt.annodbg.md5
+-- graph_primary_small.dbg
+-- graph_primary_small.dbg.md5
```

#### Sample Statistics
* 446,506 microbial genome sequences.

### SRA-MetaGut (Human Gut Microbiome)
This dataset comprises all samples classified under the human gut metagenome (TaxID: 408170), including both WGS and AMPLICON assay types, and excluding long-read sequencing platforms.

#### Dataset layout
The data is available at [s3://metagraph/metagut](https://metagraph.s3.amazonaws.com/index.html#metagut/) and has the following layout, containing both the graph as well as annotation files and the respective checksums for integrity checks:
```
s3://metagraph/metagut
+-- annotation_cluster_original.relaxed.row_diff_brwt.annodbg
+-- annotation_cluster_original.relaxed.row_diff_brwt.annodbg.md5
+-- graph_primary_small.dbg
+-- graph_primary_small.dbg.md5
```

#### Sample Statistics
* 242,619 total samples:
  * 177,759 (73.3%) AMPLICON
  * 64,860 (26.7%) WGS

### RefSeq

The RefSeq index is built from the NCBI Reference Sequence (RefSeq) database, which provides a non-redundant, curated collection of genomic DNA, transcript, and protein sequences representing assembled reference genomes.

#### Sample Statistics
* Based on **RefSeq release 97**, covering:
  * **32,881,422** nucleotide sequences
  * **1.7 Tbp** total sequence length
  * Compressed data size: **483 GB** (`gzip -9`)

#### Index Structure
Three separate indexes were constructed from the RefSeq data, each offering a different level of annotation granularity:

1. **Genus-level Taxonomy Annotation**
   * Annotated with **NCBI Taxonomy IDs** at the genus level
   * **85,375** binary annotation columns

2. **Accession-level Annotation**
   * Annotated with **sequence accessions**
   * **32,881,348** binary annotation columns

3. **K-mer Coordinate Annotation**
   * Annotated with **k-mer coordinates** split by taxonomy buckets
   * **85,375** annotation columns with **coordinate tuples**

## Usage within AWS
The following steps describe how to set up a search query across all or a subset of available index files.

### Configure the `aws` CLI tool

Please refer to the [AWS docs](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) for the installation instructions and prerequisites:

1. [Setup AWS account and credentials](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-prereqs.html);
2. [Install `aws` CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html);
3. [Setup credentials](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html).



For the third step, we recommend using Single Sign-On (SSO) authentication via [IAM Identity Center](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html#sso-configure-profile-token-auto-sso):

```sh
aws configure sso
```

You can find the SSO Start URL in your AWS access portal. **Please make sure to select `default` when prompted for profile name.**

Alternatively, you can setup your credentials using the following environment variables:

```sh
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
```

or through creation of the plain text file `~/.aws/credentials` with  the following content:

```sh
[default]
aws_access_key_id=...
aws_secret_access_key=...
aws_session_token=...
```

You can find specific tokens and keys in the "Access keys" section of your AWS access portal after signing in.

### Clone the project

```sh
git clone https://github.com/ratschlab/metagraph-open-data.git
cd metagraph-open-data
```

### Deploy the Cloud Formation template

**We assume that you work in the `eu-central-2` region, and your `aws` authentication is configured in the `default` profile.**

 The [deployment script](https://github.com/ratschlab/metagraph-open-data/blob/main/scripts/deploy-metagraph.sh) will setup the following on your AWS using the [CloudFormation template](https://github.com/ratschlab/metagraph-open-data/blob/main/metagraph-stack.yaml):

- S3 bucket to store your queries and their results;
- AWS Batch environment to execute the queries;
- Step Function and Lambdas to schedule your queries as individual Batch tasks and merge their results;
- SNS topic to send notifications to when the query is fully processed.

If you want to receive Simple Notification Service (SNS) notifications after a query is processed, you have to provide your email to the script using the `--email test@example.com` argument. **You need to confirm the subscription via a link sent in an e-mail to your mailbox.**:

```sh
scripts/deploy-metagraph.sh --email test@example.com
```

If you want to use your own Amazon Machine Image (AMI) for AWS Batch jobs (e.g., for security reasons or to support newer MetaGraph features), use `--ami ami-...` to provide your AMI ID or request that it is built using your AWS resources via `--ami build`. **The latter uses EC2 and may take up to 30 minutes!**

### Upload your query to the S3 bucket

```sh
scripts/upload-query.sh examples/test_query.fasta
```

You can upload your own queries by providing `/path/to/query.fasta` instead of [`examples/test_query.fasta`](https://github.com/ratschlab/metagraph-open-data/blob/main/examples/test_query.fasta). You can also upload `examples/100_studies_short.fq` if you would like to test the setup on a larger query.

### Submit a job

You need to describe your query in a JSON file. A minimal job definition ([`examples/scheduler-payload.json`](https://github.com/ratschlab/metagraph-open-data/blob/main/examples/scheduler-payload.json)) looks as follows:

```json
{
    "index_prefix": "all_sra",
    "query_filename": "test_query.fasta",
    "index_filter": ".*000[1-5]$"
}
```

As of now, only dataset indexes stored in `s3://metagraph` are supported. Generally, the arguments that you can provide are as follows:

- `index_prefix`, e.g. `all_sra` or `all_sra/data/metagenome`. Only chunks in the subdirectories of `index_prefix` will be considered for querying.
- `query_filename`, the filename of the query that you previously uploaded via `scripts/upload-query.sh`.
- `index_filter` (`.*` by default), a [re](https://docs.python.org/3/library/re.html)-compatible regular expression to filter paths to chunks on which the query is to be executed.

Additionally, you can specify the following parameters to be passed to the [MetaGraph CLI](https://github.com/ratschlab/metagraph) for all queried chunks:

- `query_mode` (`labels` by default),
- `num_top_labels` (`inf` by default),
- `min_kmers_fraction_label` (`0.7` by default),
- `min_kmers_fraction_graph` (`0.0` by default).

You can submit the query for execution with the following command:

```sh
scripts/start-metagraph-job.sh examples/scheduler-payload.json
```

It will create a dedicated AWS Batch job for each queried chunk, adjusting allocated memory (RAM) to the chunk size.

#### Large query example

You can use our example JSON payload for the large query in [`examples/large-query.json`](https://github.com/ratschlab/metagraph-open-data/blob/main/examples/large-query.json):

```json
{
    "index_prefix": "all_sra",
    "query_filename": "100_studies_short.fq",
    "index_filter": ".*001[0-9]$",
    "query_mode": "matches",
    "num_top_labels": "10",
    "min_kmers_fraction_label": "0"
}
```

This will execute the following command for all chunks from `0010` to `0019`:

```sh
metagraph query -i graph.primary.small.dbg \
                -a annotation.clean.row_diff_brwt.annodbg \
                --query-mode matches \
                --num-top-labels 10 \
                --min-kmers-fraction-label 0 \
                --min-kmers-fraction-graph 0 \
                100_studies_short.fq
```

Then, it will save the resulting file in the S3. When all chunks are processed, a dedicated script will merge the results in a single file and send you a notification.
