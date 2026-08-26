# Echo

With Zolt, there are a simple ways to output data to the screen: echo

The echo function can be used with or without parentheses: echo or echo().

```luau
echo "Hello";
echo("Hello");
```

### Output Text

The following example shows how to output text with the echo command (notice that the text can contain HTML markup):

```luau
echo("<h2>Lua is Fun!</h2>");
echo("Hello world!<br>");
echo("I'm about to learn Lua!<br>");
echo("This " .. "string " .. "was " .. "made " .. "with multiple strings.");
```

### Output Variables

The following example shows how to output text and variables with the echo statement:

```luau
local txt1 = "Learn Lua";
local txt2 = "with Zolt";

echo("<h2>" .. txt1 .. "</h2>");
echo("<p>Build web app in lua " .. txt2 .. "</p>");
```
