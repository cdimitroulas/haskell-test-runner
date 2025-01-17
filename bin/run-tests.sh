#!/usr/bin/env bash

# Synopsis:
# Test the test runner by running it against a predefined set of solutions 
# with an expected output.

# Output:
# Outputs the diff of the expected test results against the actual test results
# generated by the test runner.

# Example:
# ./bin/run-tests.sh

set -euo pipefail

exit_code=0

# Iterate over all test directories
for test_dir in tests/*; do
    test_dir_name=$(basename "${test_dir}")
    test_dir_path=$(realpath "${test_dir}")
    results_file_path="${test_dir_path}/results.json"
    expected_results_file_path="${test_dir_path}/expected_results.json"
    stack_root=$(stack path --stack-root)

    bin/run.sh "${test_dir_name}" "${test_dir_path}" "${test_dir_path}"

    # Normalize the results file
    sed -i -E \
      -e 's/Randomized with seed [0-9]+\\n//' \
      -e 's/Finished in [0-9]+\.[0-9]+ seconds\\n//' \
      -e 's/Completed [0-9]+ action\(s\).\\n//' \
      -e "s~${test_dir_path}~/solution~g" \
      -e 's/--builddir[^ ]+ //' \
      -e "s~${stack_root}/[^ ]+ ~~g" \
      "${results_file_path}"

    # disable -e since we want all diffs even if one has unexpected
    # results
    old_opts=$-
    set +e

    echo "${test_dir_name}: comparing results.json to expected_results.json"
    diff "${results_file_path}" "${expected_results_file_path}"

    if [ $? -ne 0 ]; then
        exit_code=1
    fi

    # re-enable original options
    set -$old_opts
done

exit ${exit_code}
