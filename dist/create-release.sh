#!/bin/sh

# Name: Lyoneel's automated releases for factorio mods
# Description: This takes info from info.json, then read targetFiles and removeFromRelease arrays to filter
# files folders and patterns, then zips with correct and structure name to ./releases folder
# version: v1.0
# modified: 2017-01-10

BASEDIR=$(dirname $0);
jsonInfo="${BASEDIR}/../info.json"
releaseDir="${BASEDIR}/releases"
rootDir="${BASEDIR}/.."
rootDirEscaped=$(echo "${rootDir}" | sed 's/\([\*\/\.]\)/\\\1/g')

targetFiles=( \
    "*.lua" \
    "info.json" \
    "prototypes" \
    "libraries" \
    "graphics" \
    "locale" \
)

removeFromRelease=( \
    "test.lua" \
    "screenshots" \
)

function JSONVal {
    echo $(cat "${1}" | jq -r ".${2}")
}

function fileWildcardExist() {
    for f in ${1}; do
        ## Check if the glob gets expanded to existing files.
        ## If not, f here will be exactly the pattern above
        ## and the exists test will evaluate to false.
        [ -e "$f" ] && echo "1" || echo "0"

        ## This is all we needed to know, so we can break after the first iteration
        break
    done
}

name=$(JSONVal ${jsonInfo} "name")
version=$(JSONVal ${jsonInfo} "version")
releaseName="${name}_${version}"
thisReleaseDir="${releaseDir}/${releaseName}"

# exist release folder?
if [ ! -d "${releaseDir}" ]; then
    mkdir "${releaseDir}";
fi

if [ -d "${thisReleaseDir}" ]; then
    rm -R "${thisReleaseDir}";
fi

mkdir "${thisReleaseDir}";

for file in "${targetFiles[@]}"; do
    if [ -f "${rootDir}/${file}" ] || [ -d "${rootDir}/${file}" ] ; then
        cp -R "${rootDir}/${file}" "${thisReleaseDir}/${file}"
        continue
    fi
    if [ $(fileWildcardExist "${rootDir}/${file}") == "1" ]; then
        tgtWildcard=${rootDir}/${file}
        # for in wildcard fails if we use more than one variable
        for fileWild in ${tgtWildcard}; do
            fileWithoutRootDir=$(echo "${fileWild}" | sed -e "s/${rootDirEscaped}\///")
            cp "${fileWild}" "${thisReleaseDir}/${fileWithoutRootDir}";
        done
        continue
    fi
done

for file in "${removeFromRelease[@]}"; do
    if [ -f "${thisReleaseDir}/${file}" ]; then
        rm "${thisReleaseDir}/${file}"
    fi
    if [ -d "${thisReleaseDir}/${file}" ]; then
        rm -R "${thisReleaseDir}/${file}"
    fi
done

# folder and files ready lets zip!
cd ${releaseDir}
zip -r "${releaseName}.zip" "${releaseName}"
rm -R "${releaseName}"
