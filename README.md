# Config Sets
Scalably maintain configs across heterogeneous clusters

# Cmdlets

## `Assert-HomogenousConfig`
Asserts whether the configs in Container are homogenous.

Throws an error if the files in Container do not share an idententical number of dash-delimeted Types
(ex: type1-type2-type3 has 3 types) and identical full file extension (ex: .params.json)

Call this function in a PR build to ensure your configs in Container are all valid

## `Assert-ParseableJson`
Assert whether the configs in Container are all valid JSON

Reads each file in Container and throws an error if any cannot be parsed as JSON

Call this function in a PR build to ensure your configs in Container are all valid


## `Select-Config`
Selects appropriate configs based on the selector

Selects all configs that match the selector with wildcards

