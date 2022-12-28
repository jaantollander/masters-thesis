\clearpage

# Lustre clients, servers and targets

Node type|Node name
-|-
service|`puhti-*`
compute|`r{01-04}c{01-48}`
compute|`r{01-04}g{01-08}`
compute|`r{05-07}c{01-64}`
compute|`r08m{01-06}`
compute|`r{09-10}c{01-48}`
compute|`r{11-12}c{01-72}`
compute|`r{13-18}c{01-48}`
compute|`r{13-18}g{01-08}`

: Node names, `{01-04}` expands to `{01,02,03,04}` and `r{a,b}` expands to `{ra,rb}`, and `{a,b}{c,d}` expands to `{ab,ad,bc,bd}`

MDT|MDS|MDT|MDS
-|-|-|-
`scratch-MDT0000`|0|`scratch-MDT0002`|1
`scratch-MDT0001`|0|`scratch-MDT0003`|1

: Metadata servers and target

OST|OSS|OST|OSS
-|-|-|-
`scratch-OST0000`|0|`scratch-OST000c`|4
`scratch-OST0001`|0|`scratch-OST000d`|4
`scratch-OST0002`|0|`scratch-OST000e`|4
`scratch-OST0003`|1|`scratch-OST000f`|5
`scratch-OST0004`|1|`scratch-OST0010`|5
`scratch-OST0005`|1|`scratch-OST0011`|5
`scratch-OST0006`|2|`scratch-OST0012`|6
`scratch-OST0007`|2|`scratch-OST0013`|6
`scratch-OST0008`|2|`scratch-OST0014`|6
`scratch-OST0009`|3|`scratch-OST0015`|7
`scratch-OST000a`|3|`scratch-OST0016`|7
`scratch-OST000b`|3|`scratch-OST0017`|7

: Object storage servers and targets

