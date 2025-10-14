#! /bin/bash
#
# ./run-benchmarks.sh -p benchmarks.csv -o outputdir -s installation-scripts/

output=
benchmarks=
scripts=

while getopts "p:o:s:" opt; do
  case "$opt" in
    p)  benchmarks=$OPTARG
        ;;
    o)  output=$(realpath $OPTARG)
        ;;
    s)  scripts=$(realpath $OPTARG)
        ;;
  esac
done
shift $(($OPTIND - 1));

if [ -z $benchmarks ]; then
  echo "You need to provide the benchmarks via -p option"
  exit 1
fi

if [ -z $output ]; then
  echo "You need to specify the directory to store results via -o option"
  exit 1
fi

if [ ! -f $benchmarks ]; then
  echo "$benchmarks is not a valid file"
fi

if [ -n $scripts ] && [ ! -f $scripts ]; then
  echo "$scripts is not a valid file"
fi


mkdir -p $output
tail -n +2 $benchmarks |
while IFS=, read -r package runtime; do
  package_base=$(basename $package)
  alternate_name="$(echo $package | sed 's|/|__|g').json"
  echo "Processing package $package..."
  echo "Installing package $package..."
  if [ -f "$scripts/$package_base.sh" ]; then
    echo "Executing custom installation script..."
    rm -rf packages/$package_base && bash $scripts/$package_base.sh
  else
    rm -rf packages/node_modules && npm install --prefix packages $package
  fi

  mod=packages/node_modues/$package
  # Adjusting CLI options for specific packages
  if [ "$package_base" = "sharp" ]; then
    mod=packages/sharp
  elif [ "$package_base" = "opencv4nodejs" ]; then
    mod=packages/opencv4nodejs
  elif [ "$package_base" = "canvas" ]; then
    mod=packages/canvas/skia.linux-x64-gnu.node
  fi

  echo "Analyzing package $package with Gasket..."
  if [ "$runtime" = "node" ]; then
    gasket -r packages/node_modules/$package --native-only \
      -o "$output/$alternate_name"
  elif [ "$runtime" = "node-internal" ]; then
    gasket -m $package --internal --native-only -o "$output/$alternate_name"
  elif [ "$runtime" = "wasm" ]; then
    gasket -r packages/node_modules/$package --force-export --wasm-only \
      -o "$output/$alternate_name"
  fi
done
