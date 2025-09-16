# Artifact for "Best of Both Worlds: Effective Foreign Bridge Identification in V8 Embedders for Security Analysis" (S&P'26)

This is the artifact for the S&P'26 paper titled
"Best of Both Worlds: Effective Foreign Bridge Identification in V8 Embedders for Security Analysis".

# Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Setup](#setup)
- [Getting Started](#getting-started)
  * [Usage](#usage)
  * [Example 1: Analyzing a Node.js Package](#example-1-analyzing-a-nodejs-package)
  * [Example 2: Analyzing a Deno Package](#example-2-analyzing-a-deno-package)

# Overview

The artifact contains the instructions to run `Gasket`,
a tool for finding all bridges from JavaScript to low-level code created
at module load time. The artifact has the following structure:

experiments presented in our paper.
* `data/`: Directory that contains information about the packages analyzed in our evaluation. 
* `node`: Directory containing the source code of Node.js
* `gasket/`: Contains the source code of the tool (provided as a git submodule).
  The name of the tool is Gasket and is used to find "bridges" between
  JavaScript and low-level code.
* `Dockerfile`: The Dockerfile used to create a Docker image of our artifact.
  This image contains all data and dependencies.

Gasket is available as open-source software under the
Apache-2.0 License, and can also be reached through the following
repository: https://github.com/grgalex/gasket.


# Requirements

__Note: This artifact has been tested on a 64-bit Ubuntu machine.
Nevertheless, our Docker image works on any given operating system
that supports Docker.__

* A [Docker](https://docs.docker.com/get-docker/) installation.
* At least 16GB of available disk space.

# Setup

The easiest way to get Gasket and all dependencies needed for evaluating 
the artifact is to download a _pre-built_ Docker 
image from DockerHub. Another option is to build the Docker 
image locally.

Docker Image
============

We provide a `Dockerfile` to build an image that contain:

* An installation of Python (version 3.10.12).
* An installation of `Gasket`.
* An installation of `node` (version todo).
* An installation of `deno` (version todo).
* An installation of `v8` (version todo).
* A user named `gasket` with sudo privileges.
* Python packages for plotting figures
  and analyzing data (i.e., `seaborn`, `pandas`, 
  `matplotlib` and `numpy`).

Pull Docker Image from DockerHub
--------------------------------

You can download the Docker image from DockerHub by using the following 
commands:

```
docker pull grgalex/gasket-eval
# Rename the image to be consistent with our scripts
docker tag grgalex/gasket-eval gasket-eval
```

After downloading the Docker image successfully, 
please navigate to the root directory of the artifact:

```
cd artifact/gasket-sp-eval
```

Build Docker Image Locally
--------------------------

With `artifact/gasket-sp-eval` as your working directory, initialize its submodules:

```
git submodule update --init --recursive
```


First enter the `gasket-sp-eval/` directory:

```
cd gasket-sp-eval
```

To build the image (named `gasket-eval`), run the following command 
(estimated running time: 30 minutes, depending on your internet 
connection):

```
docker build -t gasket-eval --no-cache .
```

**NOTE:** The image is built upon `ubuntu:24.04`.

# Getting Started

To get started with `Gasket`,
we use the Docker image named `gasket-eval`,
built according to the instructions
from the [Setup](#Setup) guide.
This image comes preconfigured with all the necessary environments
for analyzing Node or Deno packages with `Gasket`,
that is,
it includes the required installations as well as
all supporting tools needed for result processing.

You can enter a new container by using the following command:

```
sudo docker run -ti --rm --cap-add=SYS_PTRACE --security-opt seccomp=unconfined -v ./data:/home/gasket/data gasket-eval
```

## Usage

The `gasket` executable provides a command-line interface that allows you
to an analyze a given *installed* `npm` package
and identify its bridges:

```
gasket@a1a0025981b8:~$ gasket --help
Options:
  --version  Show version number                                   [boolean]
  -r, --root     Directory of the package installation to be analyzed
                                                             [string] [required]
  -o, --output   A JSON file that includes the bridges found by Gasket  [string]
      --help     Show help                                             [boolean]

```

## Example: Finding "Bridges" from JavaScript to Low-Level Code

In this section,
we illustrate the basic usage of `Gasket` by analyzing two `npm` packages:
one executed on Node.js and the other on Deno.

### Example 1: Analyzing a Node.js Package

In the first example,
we install and analyze `node-sqlite3`,
a popular `npm` package that is executed on Node.js.
Before analyzing this package with `Gasket`,
we need to install it by running:

```
gasket@a1a0025981b8:~$ mkdir -p packages
gasket@a1a0025981b8:~$ npm install --prefix packages sqlite3
```

The above commands fetch and install the `node-sqlite3` package
inside the `/home/gasket/packages/` directory.

Then,
we analyze the installed package with `Gasket` by running
(estimated running time 15--60 seconds) depending on your machine:

```
gasket@a1a0025981b8:~$ gasket -r packages/node_modules/sqlite3 -o bridges.json
```

The above command outputs a JSON file called `bridges.json` that
includes all bridges identified by `Gasket`.
This `bridges.json` file for this `node-sqlite3` example looks
like the following:

```python
{
  "objects_examined": 1426,
  "callable_objects": 943,
  "foreign_callable_objects": 28,
  "duration_sec": 131,
  "count": 28,
  "modules": [
    "/home/gasket/packages/node_modules/sqlite3/build/Release/node_sqlite3.node"
  ],
  "jump_libs": [
    "/home/gasket/packages/node_modules/sqlite3/build/Release/node_sqlite3.node"
  ],
  "bridges": [
    {
      "jsname": "sqlite3/build/Release/node_sqlite3.Database",
      "cfunc": "node_sqlite3::Database::Database",
      "library": "/home/gasket/packages/node_modules/sqlite3/build/Release/node_sqlite3.node"
    },
    {
      "jsname": "sqlite3/build/Release/node_sqlite3.Statement",
      "cfunc": "node_sqlite3::Statement::Statement",
      "library": "/home/gasket/packages/node_modules/sqlite3/build/Release/node_sqlite3.node"
    }
  # ... more bridges here ...
  ]
}
```

Below,
there's information for every key included in the resulting
JSON file:

* `objects_examined`: Counting all objects examined by `Gasket`.
* `callable_objects`: Counting all callable objects examined by `Gasket`.
* `foreign_callbable_objects`: Counting the number of callbable objects
with a foreign implementation (e.g., an implementation in C++).
* `duration`: Time spent analyzing the given package.
* `count`: The number of identified bridges.
* `modules`: The binary extension modules found in the installation of the
given package. For example, `node-sqlite` includes only one binary extension
module found at `packages/node_modules/sqlite3/build/Release/node_sqlite3.node`.
* `jump_libs`:  The binary extension modules for which `Gasket` identified bridges
that lead to them.
* `bridges`: A detailed list of identified bridges. Every bridge is a triple
containing the following information:
  - `jsname`: The name of the foreign callbable object at the JavaScript side.
  - `cfunc`: The name of the low-level function that implements the logic
   of the object exposed in JavaScript.
  - `library`: The library where this low-level function is found.

As an illustration, we describe one of the bridges shown in the JSON file
(others are omitted for brevity). In the node-sqlite package, there is a
callable object `node_sqlite3.Database`, which is implemented by the C++
class `node_sqlite3::Database::Database`.
This class resides in the library located at
`/home/gasket/packages/node_modules/sqlite3/build/Release/node_sqlite3.node`.



### Example 2: Analyzing a Deno Package

In the second example,
we show how we can use `Gasket` to analyze a Deno package.
In particular,
we analyze the [`@db/sqlite`](https://github.com/denodrivers/sqlite3)
package.

To install the package,
run:

```
gasket@a1a0025981b8:~$ git clone https://github.com/denodrivers/sqlite3 packages/deno-sqlite3
```

Then,
to analyze it using `Gasket`,
run:

```
gasket@a1a0025981b8:~$ gasket-deno -r packages/deno-sqlite3 -o deno-bridges.json
```

The output is then found in the `deno-bridges.json` file,
which looks like:

``` python
{
  "objects_examined": 7375,
  "callable_objects": 5593,
  "foreign_callable_objects": 73,
  "duration": 3,
  "count": 73
  "modules": [
    "/home/gasket/packages/deno-sqlite3/scripts/build.ts",
    "/home/gasket/packages/deno-sqlite3/deps.ts",
    "/home/gasket/packages/deno-sqlite3/src/statement.ts",
    "/home/gasket/packages/deno-sqlite3/src/util.ts",
    "/home/gasket/packages/deno-sqlite3/src/ffi.ts",
    "/home/gasket/packages/deno-sqlite3/src/constants.ts",
    "/home/gasket/packages/deno-sqlite3/src/database.ts",
    "/home/gasket/packages/deno-sqlite3/src/blob.ts",
    "/home/gasket/packages/deno-sqlite3/mod.ts",
    "/home/gasket/packages/deno-sqlite3/test/test.ts",
    "/home/gasket/packages/deno-sqlite3/test/deps.ts"
  ],
  "jump_libs": [
    "/home/gasket/.cache/deno/plug/https/github.com/78749b9d49a2ade61a15e9f85b00f70dbb4a41d888e32eb719cae983f13dead9.so"
  ],
  "bridges": [
    {
      "jsname": "sqlite3/../../../src/ffi.default.sqlite3_bind_parameter_count",
      "cfunc": "sqlite3_bind_parameter_count",
      "library": "/home/gasket/.cache/deno/plug/https/github.com/78749b9d49a2ade61a15e9f85b00f70dbb4a41d888e32eb719cae983f13dead9.so",
      "DENO_FFI": true
    },
	# more bridges
  ]
}
```

In particular,
`Gasket` found 73 bridges.
The `@db/sqlite` package is also included in our evaluation
(see Table 2 in our paper).


### Example 3: Running a large-scale analysis on multiple Node.js packages (RQ4, RQ5)

We provide the `find_bridges.py` utility to run large-scale analysis on multiple Node.js packages.

We utitlized this to calculate the bridges for the 1,266 packages evaluated in RQ4 and RQ5.

```
gasket@a75e1999faa1:~$ python3 gasket_src/scripts/find_bridges.py -h

usage: find_bridges.py [-h] [-l LOG] [-i INPUT] [-o OUTPUT] [-A]

Use Gasket to generate bridges for a set of Node.js packages.

options:
  -h, --help            show this help message and exit
  -l LOG, --log LOG     Provide logging level. Example --log debug
  -i INPUT, --input INPUT
                        Path to a CSV file with package:version pairs.
  -o OUTPUT, --output OUTPUT
                        Output directory to store bridges.
  -A, --always          Always generate artifacts; do not reuse existing data (e.g., installs).
```

We provide three CSV files under the `data/` directory:
- `gasket_packages.csv`, which holds the names of the 1,266 packages
- `gasket_packages_versioned.csv`, which holds the package:version pairs for the 1,266 packages
- `sample_packages_versioned.csv`, which holds 20 sample packages

To keep running times low, you can run the utility on 20 packages.

In this case, the results are stored in the `analysis/` directory.

```
python3 gasket_src/scripts/find_bridges.py -i data/sample_packages_versioned.csv -o analysis/
```

The utility stores results in a structured manner in the output directory.

For example, for the `tree-sitter-ride:0.1.3` package,
the corresponding bridges are stored under `analysis/data/bridges/npm/t/tree-sitter-ride/0.1.3/bridges.json`.

Additionally, the utility stores the plain bridges in text format (for direct comparison against Charon),
under the `analysis/data/gasket_bridges/` directory.

Now, you can exit the Docker container by running:

```
gasket@a1a0025981b8:~$ exit
```

