--!strict

export type Attributes = { [string]: string | boolean }
export type StyleTable = { [string]: string }

export type PrimitiveChild = string | number | boolean
export type NodeChild = Node | PrimitiveChild
export type OptionalNodeChild = NodeChild | nil

export type Node = {
    tag_name: string,
    attributes: Attributes,
    classes: { string },
    children_list: { any },

    id: (self: Node, val: string) -> Node,
    class: (self: Node, ...string?) -> Node,
    attr: (self: Node, key: string, value: (string | boolean)?) -> Node,
    style: (self: Node, styles: StyleTable | string) -> Node,
    text: (self: Node, val: (string | number)?) -> Node,
    raw: (self: Node, raw_html: string?) -> Node,
    child: (self: Node, ...OptionalNodeChild) -> Node,
    when: (self: Node, condition: any, callback: (node: Node) -> ()) -> Node,
    each: <T>(self: Node, list: { T }?, callback: (item: T, index: number) -> OptionalNodeChild) -> Node,
    render: (self: Node) -> string,
}

export type Document = {
    lang: (self: Document, l: string) -> Document,
    title: (self: Document, t: string) -> Document,
    meta: (self: Document, attrs: Attributes) -> Document,
    css: (self: Document, href: string) -> Document,
    js: (self: Document, src: string, attrs: Attributes?) -> Document,
    body: (self: Document, ...OptionalNodeChild) -> Document,
    render: (self: Document) -> string,
}

return {}
