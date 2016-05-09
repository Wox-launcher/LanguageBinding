import json, marshal, tables, os

## Helper library for Wox plugin authors
## Version 0.2.0
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

# name, proc table for call proc
var procs: Table[string, RpcProc] = initTable[string, RpcProc]()

proc register*(name: string, prc: RpcProc) =
  ## Register proc as name
  ## :param string name: name to register proc
  ## :param proc prc: proc
  procs[name] = prc

proc call*(name, params: string) =
  ## Call proc by it's name
  ## :param string name: proc name
  ## :param string params: proc parameters
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
  ##
  ## :param str title: item title
  ## :param str sub: item subtitle
  ## :param str icon: path to item icon
  ## :param str method: a function called when an item is selected
  ## :param list params: parameters for callable function
  ## :param str hide: hide Wox after select item or not

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
