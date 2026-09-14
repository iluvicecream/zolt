load("@rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "zolt_lib",
    srcs = ["main.go"]
)

go_binary(
    name = "zoltd",
    embed = [":zolt_lib"]
)