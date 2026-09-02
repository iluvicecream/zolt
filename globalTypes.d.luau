declare function echo(content: any): ()
declare request: {
    path: () -> string;
    query: (field: string) -> string;
}
declare response: {
    status: (code: number) -> ();
    header: (name: string, value: string) -> ()
}
