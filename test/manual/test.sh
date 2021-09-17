echoerr() { echo "$@" 1>&2; }

jq '.' <<EOF
{
  "thing1": {
    "cis_glyoxal-O2_2_mp2_dz_opt_1.log": [
      "MP2=-377.2487233"
    ]
  },
  "thing2": {
    "cis_glyoxal-O2_2_mp2_dz_opt_2.log": [
      "MP2=-377.195241",
      "MP2=-377.195241"
    ]
  }
}
EOF

echoerr hello world
