--!strict

local element = require("@hol-internal/element")
local document = require("@hol-internal/document")
local types = require("@hol-internal/types")

export type Attributes = types.Attributes
export type StyleTable = types.StyleTable
export type PrimitiveChild = types.PrimitiveChild
export type NodeChild = types.NodeChild
export type OptionalNodeChild = types.OptionalNodeChild
export type Node = types.Node
export type Document = types.Document

return {
    el = element.el,
    document = document.document,
}
