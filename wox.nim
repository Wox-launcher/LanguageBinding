import json, marshal, tables, os, algorithm, strutils, sequtils

## Helper library for Wox plugin authors
## Version 0.3.0
## roose 2016

type
  Action = object
    ## Wox JsonRPCAction object
    `method`: string
    parameters: seq[string]
    dontHideAfterAction: bool

  WoxItem = object
    ## Wox item object
    Title: string
    SubTitle: string
    IcoPath: string
    JsonRPCAction: Action

  WoxResult* = object
    ## Wox results object
    `result`: seq[WoxItem]

  RpcProc* = proc (params: string)

type
  SortBy* = enum
    ## Sort by title or subtitle or title and subtitle
    byTitle, bySub, byTitleSub

# name, proc table for call proc
var procs: Table[string, RpcProc] = initTable[string, RpcProc]()

proc register*(name: string, prc: RpcProc) =
  ## Register proc as name
  procs[name] = prc

proc call*(name, params: string) =
  ## Call proc by it's name
  procs[name](params)

proc run*() =
  ## Parse JsonRPC from Wox and call method with params
  let rpcRequest = parseJson(paramStr(1))
  let requestMethod = rpcRequest["method"].str
  let requestParams = rpcRequest["parameters"][0].str
  call(requestMethod, requestParams)

proc newResult*(): WoxResult =
  ## Init WoxResult

  return WoxResult(result: @[])

proc addItem*(self: var WoxResult, title, sub, icon, `method`, params: string, hide: bool = true) =
  ## Add item to the return list

  self.result.add(WoxItem(
                    Title: title,
                    SubTitle: sub,
                    IcoPath: icon,
                    JsonRPCAction: Action(
                      `method`: `method`,
                      parameters: @[params],
                      dontHideAfterAction: hide
                    )
                 ))

proc results*(self: var WoxResult): string =
  ## Return results with all items
  return $$self

proc sort*(self: var WoxResult, query: string, sortBy = byTitleSub) =
  ## Fuzzy sorting the results, default sorted by title and subtitle

  proc score(value: string): float =
    ## Calculate score

    var score = 0.0
    if value.toLower.startsWith(query):
      score = 100.0 - (value.len / query.len)
    elif query in value.toLower:
      score = 80.0 - (value.len / query.len)
    return score

  self.result.sort(
    proc(x, y: WoxItem) :int =
      var text: array[0..1, string]
      case sortBy:
        of byTitle:
          text = [x.Title, y.Title]
        of bySub:
          text = [x.SubTitle, y.SubTitle]
        of byTitleSub:
          text = [x.Title & " " & x.SubTitle, y.Title & " " & y.SubTitle]
        else:
          text = [x.Title & " " & x.SubTitle, y.Title & " " & y.SubTitle]
      cmp(score(text[0]), score(text[1])), SortOrder.Descending
  )