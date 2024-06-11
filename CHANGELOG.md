# CHANGELOG

## v1.0
### High level changes 
- released as a new gem called passbook2
  maintains the Passbook namespace because passbook2 replaces passbook and you shouldn't have to type 2 all the time. 😉
- changed method names that were camel case (e.g. `addFile`) to snake case (`add_file`).
- removed generator stuff
- removed requirement for p12 files which Apple no longer supports
- added comments
- README actually reflects the current state of the library

## Breaking code changes
(breaking from the the pre-release version of this fork)


- removed depricated methods in `PKPass` 
  - `json=(json)`
- changed public method names
  - `addFile` → `add_file`
  - `addFiles` → `add_files`
  - `files` → `list_files`
    This change was to disambiguate from the `file` method which generates a file.
- changed private method names 
  - `checkPass` → `check_pass`
  - `createManifest` → `create_manifest`
  - `outputZip` → `output_zip`
