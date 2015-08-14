# Stack Trace Formatter

StackTraceFormatter is a single C# function that can format a stack trace text
output (typically returned by [`Environment.StackTrace`][envst] or
[`Exception.StackTrace`][exst]) with arbitrary markup via the following
interface:

```c#
interface IStackTraceFormatter<T>
{
    T Text             (string text);
    T Type             (T markup);
    T Method           (T markup);
    T ParameterType    (T markup);
    T ParameterName    (T markup);
    T File             (T markup);
    T Line             (T markup);
    T BeforeFrame      { get; }
    T AfterFrame       { get; }
    T BeforeParameters { get; }
    T AfterParameters  { get; }
}
```

It is available as a [NuGet *source* package][srcpkg] that directly embeds into
a C# project.

## Usage

`StackTraceFormatter` has a function called `Format` that takes the source
text to parse and an interface that is called back to markup the parsed
elements of a stack trace, like frames and method signatures:

```c#
static IEnumerable<T> Format<T>(string text, IStackTraceFormatter<T> formatter)
```

The `Format` function is probably too generic for most applications. If you are
looking to simply markup a stack trace with HTML then you will want to use
`FormatHtml` instead:

```c#
static string FormatHtml(string text, IStackTraceFormatter<string> formatter)
```

An implementation of `IStackTraceFormatter<string>`, called
`StackTraceHtmlFragments`, is included and which can be passed as the second
parameter to `FormatHtml`:

```c#
class StackTraceHtmlFragments : IStackTraceFormatter<string>
{
    public string BeforeType          { get; set; }
    public string AfterType           { get; set; }
    public string BeforeMethod        { get; set; }
    public string AfterMethod         { get; set; }
    public string BeforeParameterType { get; set; }
    public string AfterParameterType  { get; set; }
    public string BeforeParameterName { get; set; }
    public string AfterParameterName  { get; set; }
    public string BeforeFile          { get; set; }
    public string AfterFile           { get; set; }
    public string BeforeLine          { get; set; }
    public string AfterLine           { get; set; }
    public string BeforeFrame         { get; set; }
    public string AfterFrame          { get; set; }
    public string BeforeParameters    { get; set; }
    public string AfterParameters     { get; set; }

    // Rest of class definition omitted here for brevity...
}
```

`StackTraceHtmlFragments` allows use of [C#'s object initializer syntax][csobjinit]
to conveniently define the HTML to insert literally before and after the
various parsed elements of a stack trace.

Suppose [`Environment.StackTrace`][envst] returns (produced here by running
`Environment.StackTrace` as an expression in [LINQPad][linqpad]):

    at System.Environment.GetStackTrace(Exception e, Boolean needFileInfo)
    at System.Environment.get_StackTrace()
    at UserQuery.RunUserAuthoredQuery() in c:\Users\johndoe\AppData\Local\Temp\LINQPad\_piwdiese\query_dhwxhm.cs:line 33
    at LINQPad.ExecutionModel.ClrQueryRunner.Run()
    at LINQPad.ExecutionModel.Server.RunQuery(QueryRunner runner)
    at LINQPad.ExecutionModel.Server.StartQuery(QueryRunner runner)
    at LINQPad.ExecutionModel.Server.<>c__DisplayClass36.<ExecuteClrQuery>b__35()
    at LINQPad.ExecutionModel.Server.SingleThreadExecuter.Work()
    at System.Threading.ThreadHelper.ThreadStart_Context(Object state)
    at System.Threading.ExecutionContext.RunInternal(ExecutionContext executionContext, ContextCallback callback, Object state, Boolean preserveSyncCtx)
    at System.Threading.ExecutionContext.Run(ExecutionContext executionContext, ContextCallback callback, Object state, Boolean preserveSyncCtx)
    at System.Threading.ExecutionContext.Run(ExecutionContext executionContext, ContextCallback callback, Object state)
    at System.Threading.ThreadHelper.ThreadStart()

You could then markup the frames of the above stack trace in HTML like this:

```c#
var html = "<pre><code>"
         + StackTraceFormatter.FormatHtml(
             Environment.StackTrace,
             new StackTraceHtmlFragments
             {
                 BeforeFrame = "<span class='frame'>",
                 AfterFrame  = "</span>",
             })
         + "</code></pre>";
```

The content of the `html` string after execution of the above line would be:

```html
<pre><code>
at <span class='frame'>System.Environment.GetStackTrace(Exception e, Boolean needFileInfo)</span>
at <span class='frame'>System.Environment.get_StackTrace()</span>
at <span class='frame'>UserQuery.RunUserAuthoredQuery() in c:\Users\johndoe\AppData\Local\Temp\LINQPad\_piwdiese\query_dhwxhm.cs:line 33</span>
at <span class='frame'>LINQPad.ExecutionModel.ClrQueryRunner.Run()</span>
at <span class='frame'>LINQPad.ExecutionModel.Server.RunQuery(QueryRunner runner)</span>
at <span class='frame'>LINQPad.ExecutionModel.Server.StartQuery(QueryRunner runner)</span>
at <span class='frame'>LINQPad.ExecutionModel.Server.&lt;&gt;c__DisplayClass36.&lt;ExecuteClrQuery&gt;b__35()</span>
at <span class='frame'>LINQPad.ExecutionModel.Server.SingleThreadExecuter.Work()</span>
at <span class='frame'>System.Threading.ThreadHelper.ThreadStart_Context(Object state)</span>
at <span class='frame'>System.Threading.ExecutionContext.RunInternal(ExecutionContext executionContext, ContextCallback callback, Object state, Boolean preserveSyncCtx)</span>
at <span class='frame'>System.Threading.ExecutionContext.Run(ExecutionContext executionContext, ContextCallback callback, Object state, Boolean preserveSyncCtx)</span>
at <span class='frame'>System.Threading.ExecutionContext.Run(ExecutionContext executionContext, ContextCallback callback, Object state)</span>
at <span class='frame'>System.Threading.ThreadHelper.ThreadStart()</span></code></pre>
```

Note also how the source text is also correctly escaped per HTML rules.

Here is another example that highlights methods and declaring types and
emphasises parameter names:

```c#
var html = "<pre><code>"
         + StackTraceFormatter.FormatHtml(
             Environment.StackTrace,
             new StackTraceHtmlFragments
             {
                 BeforeType          = "<strong>",    // highlight type
                 AfterMethod         = "</strong>",   // ...and method
                 BeforeParameterName = "<em>",        // emphasise parameter names
                 AfterParameterName  = "</em>",
             })
         + "</code></pre>";
```

And now the `html` variable would read:

```html
<pre><code>
at <strong>System.Environment.GetStackTrace</strong>(Exception <em>e</em>, Boolean <em>needFileInfo</em>)
at <strong>System.Environment.get_StackTrace</strong>()
at <strong>UserQuery.RunUserAuthoredQuery</strong>() in c:\Users\johndoe\AppData\Local\Temp\LINQPad\_piwdiese\query_dhwxhm.cs:line 33
at <strong>LINQPad.ExecutionModel.ClrQueryRunner.Run</strong>()
at <strong>LINQPad.ExecutionModel.Server.RunQuery</strong>(QueryRunner <em>runner</em>)
at <strong>LINQPad.ExecutionModel.Server.StartQuery</strong>(QueryRunner <em>runner</em>)
at <strong>LINQPad.ExecutionModel.Server.&lt;&gt;c__DisplayClass36.&lt;ExecuteClrQuery&gt;b__35</strong>()
at <strong>LINQPad.ExecutionModel.Server.SingleThreadExecuter.Work</strong>()
at <strong>System.Threading.ThreadHelper.ThreadStart_Context</strong>(Object <em>state</em>)
at <strong>System.Threading.ExecutionContext.RunInternal</strong>(ExecutionContext <em>executionContext</em>, ContextCallback <em>callback</em>, Object <em>state</em>, Boolean <em>preserveSyncCtx</em>)
at <strong>System.Threading.ExecutionContext.Run</strong>(ExecutionContext <em>executionContext</em>, ContextCallback <em>callback</em>, Object <em>state</em>, Boolean <em>preserveSyncCtx</em>)
at <strong>System.Threading.ExecutionContext.Run</strong>(ExecutionContext <em>executionContext</em>, ContextCallback <em>callback</em>, Object <em>state</em>)
at <strong>System.Threading.ThreadHelper.ThreadStart</strong>()</code></pre>
```

You get the idea!

## Background

`StackTraceFormatter`, together with [StackTraceParser][parser], was born as
part of the [ELMAH][elmah] project and used to [color the stack
traces][elmaheg], as can be seen from the screenshot below:

![ELMAH](http://www.hanselman.com/blog/content/binary/Windows-Live-Writer/NuGet-Package-of-the-Week-7---ELMAH-Erro_B9F2/Error_%20System.Web.HttpException%20%5B30158b95-0112-4081-91ab-c5ec7848a12c%5D%20-%20Windows%20Internet%20Explorer%20(74)_2.png)

See the [`ErrorDetailPage` source code][errdp] from the ELMAH repo for a real
example of [how the output of `StackTraceParser` was used for marking up the
stack trace in HTML][elmaheg].

  [envst]: https://msdn.microsoft.com/en-us/library/system.environment.stacktrace(v=vs.110).aspx
  [exst]: https://msdn.microsoft.com/en-us/library/system.exception.stacktrace(v=vs.110).aspx
  [srcpkg]: https://www.nuget.org/packages/StackTraceFormatter.Source
  [elmah]: https://elmah.github.io/
  [elmaheg]: https://bitbucket.org/project-elmah/main/src/2a6b0b5916a6b4913ca5af4c22c4e4fc69f1260d/src/Elmah.AspNet/ErrorDetailPage.cs?at=default#ErrorDetailPage.cs-45
  [errdp]: https://bitbucket.org/project-elmah/main/src/2a6b0b5916a6b4913ca5af4c22c4e4fc69f1260d/src/Elmah.AspNet/ErrorDetailPage.cs?at=default
  [linqpad]: https://www.linqpad.net/
  [parser]: https://github.com/atifaziz/StackTraceParser
  [csobjinit]: https://msdn.microsoft.com/en-us/library/bb384062.aspx
