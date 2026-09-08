These are reference-only metadata files from the original dumketo source/release line.

Do NOT point the ported project at the original patches-bundle.json when testing:
its download_url still points to the old v1.0.0 .mpp that declares/requires the
obsolete 2.0.1 patcher lineage.

Also note: the original patches-list.json advertised a "dnsServers" option for
the AdGuard Custom DNS patch, but the corresponding Kotlin source contains no
such option. The port intentionally does not invent missing upstream behavior.
