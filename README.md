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
* [SRA MetaGut](#sra-metagut-human-gut-microbiome)
* [SRA Microbe](#sra-microbe)
* [RefSeq](#refseq)
* [Unified Human Gastrointestinal Genome](#unified-human-gastrointestinal-genome-uhgg)
* [Tara Oceans](#tara-oceans)

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
  125,585 samples processed; 121,900 (97.1%) successfully cleaned.
* **Plants** (Viridiplantae; TaxID: 33090):
  576,226 samples processed; 531,714 (92.3%) successfully cleaned.
* **Human** (Homo sapiens; TaxID: 9606):
  454,252 samples processed; 436,494 (96.1%) successfully cleaned.
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
* 241,384 total samples:
  * 176,735 (73.2%) AMPLICON
  * 64,849 (26.9%) WGS

### RefSeq

The RefSeq index is built from the NCBI Reference Sequence (RefSeq) database, which provides a non-redundant, curated collection of genomic DNA, transcript, and protein sequences representing assembled reference genomes.

#### Sample Statistics
* Based on **RefSeq release 97**, covering:
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
  
### Unified Human Gastrointestinal Genome (UHGG)

This dataset consists of high-quality assemblies of genomes from human gut microbiomes, catalogued [here](https://www.ebi.ac.uk/metagenomics/genome-catalogues/human-gut-v2-0-2). We provide indexes for v1.0 of the dataset.

#### Dataset layout
The data is available at [s3://metagraph/uhgg_catalogue](https://metagraph.s3.amazonaws.com/index.html#uhgg_catalogue/) and [s3://metagraph/uhgg_all](https://metagraph.s3.amazonaws.com/index.html#uhgg_all/). An example layout for `uhgg_all`, containing both the graph as well as annotation files and the respective checksums for integrity checks:
```
s3://metagraph/uhgg_all
+-- annotation.relaxed.relabeled.row_diff_brwt.annodbg
+-- annotation.relaxed.relabeled.row_diff_brwt.annodbg.md5
+-- graph_complete_k31.dbg
+-- graph_complete_k31.dbg.md5
+-- graph_complete_k31.small.dbg
+-- graph_complete_k31.small.dbg.md5
```

#### Sample Statistics
* UHGG (catalogue):
  * **4,644** reference genomes
* UHGG (all sequences):
  * **286,997** non-redundant genomes

### Tara Oceans

This collection contains genomes reconstructed from metagenomic data sets from major oceanographical surveys of global ocean microbial communities across ocean basins, depth layers, and time. The dataset is augmented with reference genome sequences of marine bacteria and archaea from other existing databases. For more details on the data composition, refer to the [original publication](https://www.nature.com/articles/s41586-022-04862-3).

#### Dataset layout
The data is available at [s3://metagraph/tara_oceans](https://metagraph.s3.amazonaws.com/index.html#tara_oceans/). Indexes are provided for both the genomes (`genomes_*`) and scaffolds (`scaffolds_*`). The genome index has annotations for both k-mer presence/absence (i.e., binary; `genomes_annotation.row_diff_brwt.annodbg`) and for coordinates (`genomes_annotation.row_diff_brwt_coord.annodbg`). The layout for `tara_oceans`, containing both the graph as well as annotation files and the respective checksums for integrity checks:
```
s3://metagraph/uhgg_all
+-- genomes_annotation.row_diff_brwt.annodbg
+-- genomes_annotation.row_diff_brwt.annodbg.md5
+-- genomes_annotation.row_diff_brwt_coord.annodbg
+-- genomes_annotation.row_diff_brwt_coord.annodbg.md5
+-- genomes_graph.dbg
+-- genomes_graph.dbg.md5
+-- genomes_graph_small.dbg
+-- genomes_graph_small.dbg.md5
+-- scaffolds_annotation.row_diff_flat.annodbg
+-- scaffolds_annotation.row_diff_flat.annodbg.md5
+-- scaffolds_graph.dbg
+-- scaffolds_graph.dbg.md5
+-- scaffolds_graph_small.dbg
+-- scaffolds_graph_small.dbg.md5
```

#### Sample Statistics
* **34,815** genomes
* **318,205,057** scaffolds

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

**We assume that you work in the `eu-west-1` region, and your `aws` authentication is configured in the `default` profile.**

 The [deployment script](https://github.com/ratschlab/metagraph-open-data/blob/main/scripts/deploy-metagraph.sh) will setup the following on your AWS using the [CloudFormation template](https://github.com/ratschlab/metagraph-open-data/blob/main/metagraph-stack.yaml):

- S3 bucket to store your queries and their results;
- AWS Batch environment to execute the queries;
- Step Function and Lambdas to schedule your queries as individual Batch tasks and merge their results;
- SNS topic to send notifications to when the query is fully processed.

The script has the following usage pattern:

```sh
scrpts/deploy-metagraph.sh [--build-ami] [--ami <ami-id>] [--arm-ami <arm-ami-id>] [--email your@email.com] [--interactive]
```

If you want to be guided in an interactive manner, you can simply use `scripts/deploy-metagraph.sh --interactive`.

If you want to receive Simple Notification Service (SNS) notifications after a query is processed, you will have to provide your email. **You need to confirm the subscription via a link sent in an e-mail to your mailbox**.

You can use the default Amazon Machine Images (AMI) for AWS Batch jobs, provide your own or build them using the recipe from [metagraph-ami.yaml](https://github.com/ratschlab/metagraph-open-data/blob/main/metagraph-ami.yaml) (e.g., for security reasons or to support newer MetaGraph features). **The latter uses EC2 and may take up to 30 minutes!**

### Request quota increase

As querying MetaGraph is computationally demanding, you would need to use a lot of on-demand EC2 instances. The stack is designed to use `r6in` instances for smaller queries (load-bound) and `hpc7g` instances for larger queries (compute-bound). As the default quotas are pretty low, you'd likely need to request an increase for [standard instances](https://eu-west-1.console.aws.amazon.com/servicequotas/home/services/ec2/quotas/L-1216C47A), which includes `r6in`, as well as [HPC instances](https://eu-west-1.console.aws.amazon.com/servicequotas/home/services/ec2/quotas/L-F7808C92) (assuming that you expect to work with queries larger than 10 MiB).

### Upload your query to the S3 bucket

```sh
scripts/upload-query.sh examples/test_query.fasta
```

You can upload your own queries by providing `/path/to/query.fasta` instead of [`examples/test_query.fasta`](https://github.com/ratschlab/metagraph-open-data/blob/main/examples/test_query.fasta). You can also upload `examples/100_studies_short.fq` if you would like to test the setup on a larger query.

### Submit a job

You can use `scripts/start-metagraph-job.sh` to submit a job to the query system:

```sh
scripts/start-metagraph-job.sh --query-filename test_query.fasta --index-filter 000[1-9]
```

It will create a dedicated AWS Batch job for each queried chunk, adjusting allocated memory (RAM) to the chunk size.

You can use `start-metagraph-job.sh` with parameters `-h` to read a help message with the list of possible parameters, or `--interactive` to specify parameters in an interactive manner. Notable parameters:

- `cmd`: command to pass to the [MetaGraph CLI](https://github.com/ratschlab/metagraph) (e.g. `query` or `align`).
- `query-filename` (required): the names of the query file that was already uploaded with `upload-query.sh`, e.g. `test_query.fasta` or `100_studies_short.fq`.
- `index-prefix` (default: `all_sra/data/metagenome`): the prefix on [s3://metagraph](https://metagraph.s3.amazonaws.com/index.html). Only chunks in the subdirectories of `index_prefix` will be considered for querying.
- `index-filter` (default: `.*`): an [re](https://docs.python.org/3/library/re.html)-compatible regular expression to filter paths to chunks on which the query is to be executed.
- `graph-suffix` (default: `small.dbg`) and `anno-suffix` (default: `brwt.annodbg`): specify graph and annotation representations, as encoded in their file extensions.
- `merge` (default: `true`): whether to merge results into single file. Only supported for `query` in `labels` and `matches` query modes.
- `extra_args`: anything else you would like to pass to the CLI in the free form.

In the end, you will be sent a notification containing a link to download merged results (valid for 7 days), and a cost estimation for the query. Note: The cost estimation assumes that it was the only query active at the time, and will likely provide inaccurate results otherwise.