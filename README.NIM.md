# nim-wox

Wox plugins binding and helper Nim package

## Example usage

```nimrod
import json, wox, strutils, browsers, httpclient

proc getPackages(query: string): JsonNode =
  let content = getContent("http://npmsearch.com/query?fields=name,description,author,version,homepage&sort=rating:desc&q=name:" & query)
  return parseJson(content)
  
proc query*(query: string) = 
  # init wox results
  var result = wox.newResult()
  let packages = getPackages(query)["results"]

  # parse items and add to results
  for item in packages:
    let title = "$1 v$2 by $3" % [item["name"][0].str, item["version"][0].str, item["author"][0].str]
    let desc = item["description"][0].str
    let url = item["homepage"][0].str
    result.addItem(title, desc, "Images\\exe.png", "openUrl", url, false)
  # sort results
  result.sort(query)
  # print results json
  echo result.results()
  
proc openUrl(url: string) =
  openDefaultBrowser(url)

when isMainModule:
  wox.register("query", query)
  wox.register("openUrl", openUrl)
  wox.run()
```