#!/bin/bash
# ------------------ SCRIPT INFO: functions.sh -------------------- #
# PURPOSE
# - Organization of code chunks used in more than one script

# ----------------- SCRIPT START -------------------- # 

# remove negative and positive controls
qiime feature-table filter-features \
    --i-table "$tableQZA" \
    --m-metadata-file "$MAPname" \
    --p-where "[$controlCol] IN ($controlName, $mockname)" \
    --p-exclude-ids TRUE \
    --o-filtered-table "$outputDir"/sample-table.qza

# remove samples not in map file  
qiime feature-table filter-samples \
    --i-table "$outputDir"/sample-table.qza \
    --m-metadata-file "$MAPname" \
    --o-filtered-table "$outputDir"/filtered-table.qza
