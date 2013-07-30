## Crude and not very robust script to exclude externals from our Pd-extended.app, with the exception of those specified in supported_pd_externals.txt and supported_host_externals.txt
mv host/extra ./
cat ../host/Pd/supported_host_externals.txt ../SDK/ModuleCreator/src/assets/supported_pd_externals.txt | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; /^$/d' | while read line;do rsync -R extra/"$line".dylib extra/"$line".pd extra/"$line".pd_darwin extra/"$line"-help.pd host/ extra/extra/"$line".pd_darwin extra/extra/"$line"-help.pd host/;done
mv extra/vanilla host/extra
rm -rf extra
