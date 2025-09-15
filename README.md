# Artifact for "Best of Both Worlds: Effective Foreign Bridge Identification in V8 Embedders for Security Analysis" (S&P'26)

This is the artifact for the S&P'26 paper titled
"Best of Both Worlds: Effective Foreign Bridge Identification in V8 Embedders for Security Analysis".

# Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Setup](#setup)
- [Getting Started](#getting-started)
  * [Usage](#usage)
  * [Example: Validating the Pattern-Match Coverage Analyzer of Scala](#example-validating-the-pattern-match-coverage-analyzer-of-scala)
- [Step by Step Instructions](#step-by-step-instructions)
  * [RQ1: Bug-Finding Results (Section 5.2)](#rq1-bug-finding-results-section-52)
  * [RQ2: Bug and Test Case Characteristics (Section 5.3)](#rq2-bug-and-test-case-characteristics-section-53)
  * [RQ3: Performance (Section 5.4)](#rq3-performance-section-54)
  * [Re-running Experiments and Reproducing Tables and Figures with New Data (Optional)](#re-running-experiments-and-reproducing-tables-and-figures-with-new-data-optional)

# Overview

The artifact contains the instructions and scripts to re-run the evaluation
described in our paper. The artifact has the following structure:

* `scripts/`: This directory contains the scripts needed to re-run the
experiments presented in our paper.
* `data/`: This is the directory that contains the precomputed results of our
evaluation.
* `gasket/`: Contains the source code of the tool (provided as a git submodule).
  The name of the tool is Gasket and is used to find "bridges" between
  JavaScript and low-level code.
* `figures/`: This directory will be used to save the reproduced
figures of our paper.
* `Dockerfile`: The Dockerfile used to create a Docker image of our artifact.
  This image contains all data and dependencies.

Gasket is available as open-source software under the
GNU General Public License v3.0, and can also be reached through the following
repository: https://github.com/grgalex/gasket.


# Requirements

__Note: This artifact has been tested on a 64-bits Ubuntu machine.
Nevertheless, our Docker image works on any given operating system
that supports Docker.__

* A [Docker](https://docs.docker.com/get-docker/) installation.
* At least 16GB of available disk space.

# Setup

To get the artifact, run:

```
git clone --recursive https://github.com/theosotr/gasket-sp-eval
```

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
cd gasket-eval
```

Build Docker Image Locally
--------------------------

First enter the `gasket-eval/` directory:

```
cd gasket-eval
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
docker run -ti --rm gasket-eval
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


```
TODO
```

# Step By Step Instructions

**NOTE**: Before proceeding with instructions included
in this Section, make sure that you have successfully
built the Docker image named `gasket-eval`
(see the instructions included in the [Setup](#setup) guide).

To validate the main results presented in the paper,
first create a new Docker
container by running:

```
docker run -ti --rm \
  -v $(pwd)/data:/home/gasket/data \
  -v $(pwd)/scripts:/home/gasket/eval-scripts \
  -v $(pwd)/figures:/home/gasket/eval-figures \
  -v $(pwd)/new-results:/home/gasket/new-results \
  gasket-eval
```

Note that we mount four _local volumes_ inside the newly created container.
The first volume (`data/`) contains the data collected during our evaluation,
including the bugs discovered by `Gasket`.
The second volume (`eval-scripts/`) includes
all necessary scripts to reproduce
and validate the results of the paper.
The third volume (`eval-figures/`) is used to save the figures of our paper.
Finally,
the last volume (`new-results/`) mounts an empty directory where
you can store the results if you decide to re-run our experiments.


**NOTE**: Recomputing all the results presented in our paper takes
approximately three days.


## RQ1: Gasket Effectiveness (Section 6.1)

TODO

## RQ2: Gasket Performance (Section 6.2)

TODO

## RQ3: Gasket Applicability (Section 6.3)

TODO

## RQ4: Gasket vs. Charon (Section 6.4)

TODO

## RQ5: Reachability Analysis with Gasket (Section 6.5)

TODO
