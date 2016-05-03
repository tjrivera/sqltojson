# SQL to JSON

Tool to build/export JSON documents from nested SQL queries.

Currently the data output is in the [bulk format](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html) for loading into Elasticsearch. In addition, a base [mapping file](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html) is auto-generated by inferring the types from the data.

## Install

Requires

* [Glide](https://glide.sh)
* Go >=1.5 with `GO15VENDOREXPERIMENT=1`

```
git clone https://github.com/chop-dbhi/sqltojson.git && cd sqltojson
glide -y glide.lock install
make build
```

## Config

Create a config file. See the included [config.example.yaml](./config.example.yaml) for a real world example.

- `workers` - Number of workers. Defaults to 10.
- `connections` - Max number of connections to the database. Defaults to 10.
- `files.data` - Name of the file to write the data to. Defaults to `data.json`. For more control, set the name to `-` which will write the data to stdout. This makes it easy to pipe to `gzip` or perform other operations especially for large exports.
- `files.mapping` - Name of the file to write the mapping to.
- `index` - Name of the ES index the data applies to.
- `type` - Name of the ES document type the data applies to.
- `schema` - The schema of the documents being created.

## Usage

Create a config file and then run.

```bash
sqltojson -config config.yaml
```

If `files.data` is set to `-`, the output will be written to stdout. This may be preferable for large exports to the data can be compressed.

```bash
sqltojson -config config-stdout.yaml | gzip -c > data.json.gz


## Elasticsearch

The output files are named `data.json` and `mapping.json` by default.

### Create Index

```bash
curl -XPOST http://192.168.99.100:9200/my_index -d @mapping.json
```

### Load Data

```bash
curl -XPOST http://192.168.99.100:9200/_bulk --data-binary @data.json
```

## Troubleshooting

**"Connection reset by peer" during a data load**

Elasticsearch has a limit to how large the request body can be for a single HTTP request. This is specified by the `http.max_content_length` setting which is [100 MB by default](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-http.html).

One solution is to increase the limit, however all of the data does need to be kept in memory and is limited to about 4 GB, so there may be a hard limit on what is practical.

A better solution is to chunk up the output file into sizes smaller than that setting and load them sequentially. This can be done using the `split` command available on Linux and OS X platforms.

Create a directory to split the files into.

```bash
mkdir data
```

`cd` into and split the file so the new files are written in the directory. The files will be named liked `xaa`, `xab`, etc. Choose an even number of lines where the total file size is less than the `http.max_content_length`.

```bash
cd data
split -l 10000 ../data.json
```

Loop over each file in order and bulk load it.

```bash
for f in `ls . | sort`; do
    curl -X POST http://192.168.99.100:9200/_bulk --data-binary "@$f"
done
```

On a side note, the HTTP response is not terribly informative and is on board to be changed to a [413 Request Entity to Large](https://github.com/elastic/elasticsearch/issues/2902).
