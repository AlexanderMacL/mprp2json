# mprp2json
Scripts to convert between MPR profile files, and JSON-encoded data

## Why is this useful?
You could use this code to:
* Examine and edit your profile files without using PCS's software, e.g. on your own computer
* Create your profile files using a script instead of having to do it manually, e.g. incorporating film thickness calculations
* Bulk-edit profile files for parameter sweeps or to match conditions between samples/fluids

## Why JSON?
JSON (JavaScript Object Notation) is both human-readable (you can open it in Notepad) and machine-readable. **An example JSON file is provided.**

A minimal working JSON file takes the following form:
```
{
  "Type": "MPR profile",
  "Name": "This test contains 1 suspend step, so doesn't do much",
  "contactLength": 1.000,
  "Steps": [
    {
      "stepType": "Suspend",
      "stepName": "Suspend step",
      "stepText": "Test suspended chaps!"
    }
  ]
}
```


## Notes
1. The scripts are written in MATLAB 2021a, and will work if you just open them in MATLAB and press Run. They can also be used as functions in your own script to create more complex profile files.
2. JSON files must contain at least all of the parameters listed under the relevant step(s) in the `jsonExample.json` file. Any parameters with names other than these are ignored by the scripts, but may be useful for your records, e.g. storing the results of film thickness calculations.
3. If anything goes wrong, let me know! dam216@ic.ac.uk

#### Author
Alexander MacLaren, dam216@ic.ac.uk

Tribology Group, Dept. Mechanical Engineering, Imperial College London

