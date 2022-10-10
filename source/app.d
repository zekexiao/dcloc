module loc;
import std.stdio;
import std.file;
import std.string;
import std.range;
import std.path;
import std.conv;
import std.getopt;
import std.math;
import tabular;

struct AppOpt
{
	bool countFileSize = false;
}

enum LangEnum
{
	d,
	cpp,
	go,
	rust,
	bash,
	python,
	ruby,
	java,
	markDown,
	html,
	yaml,
	json,
	javaScript,
	typeScript,
	other,
}

LangEnum[string] extLangMap;
string[LangEnum] displayNameLangMap;
AppOpt appOpt;

static this()
{
	extLangMap = [
		".d": LangEnum.d,
		".cpp": LangEnum.cpp,
		".c": LangEnum.cpp,
		".h": LangEnum.cpp,
		".go": LangEnum.go,
		".rs": LangEnum.rust,
		".sh": LangEnum.bash,
		".py": LangEnum.python,
		".rb": LangEnum.ruby,
		".java": LangEnum.java,
		".md": LangEnum.markDown,
		".html": LangEnum.html,
		".yaml": LangEnum.yaml,
		".json": LangEnum.json,
		".js": LangEnum.javaScript,
		".ts": LangEnum.typeScript
	];

	displayNameLangMap = [
		LangEnum.d: "D",
		LangEnum.cpp: "C++",
		LangEnum.go: "Go",
		LangEnum.rust: "Rust",
		LangEnum.bash: "Bash",
		LangEnum.python: "Python",
		LangEnum.ruby: "Ruby",
		LangEnum.java: "Java",
		LangEnum.markDown: "MarkDown",
		LangEnum.html: "HTML",
		LangEnum.yaml: "YAML",
		LangEnum.json: "JSON",
		LangEnum.javaScript: "JavaScript",
		LangEnum.typeScript: "TypeScript",
	];
}

string[][] getLangCommentPrefix(LangEnum lang)
{
	string[][] noComment;
	string[][] cStyleComment = [["//"], ["/*", "*/"]];
	switch (lang)
	{
	case LangEnum.html:
		return [["<!--", "--!>"]];
	case LangEnum.python:
		return [["#"], [`"""`, `"""`]];
	case LangEnum.bash:
	case LangEnum.yaml:
		return [["#"]];
	case LangEnum.ruby:
		return [["#"], ["=begin", "=end"]];
	case LangEnum.json:
		return noComment;
	default:
		return cStyleComment;
	}
}

struct LangCount
{
	LangEnum type;
	int files;
	int lines;
	int comment;
	int code;
	int blank;
	ulong fileSize;
}

void printResult(ref LangCount*[LangEnum] result)
{
	// format 1024 -> 1.00KB
	string formatFileSize(double fileSize)
	{
		string rate;
		if (fileSize < pow(1024, 1))
		{
			rate = "B";
		}
		else if (fileSize < pow(1024, 2))
		{
			rate = "KB";
			fileSize /= 1024;
		}
		else if (fileSize < pow(1024, 3))
		{
			rate = "MB";
			fileSize /= pow(1024, 2);
		}
		else if (fileSize < pow(1024, 4))
		{
			rate = "GB";
			fileSize /= pow(1024, 3);
		}
		else if (fileSize < pow(1024, 5))
		{
			rate = "TB";
			fileSize /= pow(1024, 4);
		}
		return format("%.2f%s", fileSize, rate);
	}

	string[][] data = [
		["Language", "File", "Code", "Comment", "Blank", "Lines"]
	];

	LangCount sumCount;
	foreach (val; result)
	{
		if (auto name = val.type in displayNameLangMap)
		{
			sumCount.files += val.files;
			sumCount.code += val.code;
			sumCount.comment += val.comment;
			sumCount.blank += val.blank;
			sumCount.lines += val.lines;
			sumCount.fileSize += val.fileSize;

			auto line = [
				*name, to!string(val.files), to!string(val.code),
				to!string(val.comment), to!string(val.blank),
				to!string(val.lines)
			];

			if (appOpt.countFileSize)
			{
				line ~= formatFileSize(val.fileSize);
			}
			data ~= line;
		}
	}

	data ~= [""];
	data ~= [
		"Total", to!string(sumCount.files), to!string(sumCount.code),
		to!string(sumCount.comment), to!string(sumCount.blank),
		to!string(sumCount.lines)
	];

	if (appOpt.countFileSize)
	{
		data[0] ~= "Files Size";
		data[$ - 1] ~= formatFileSize(sumCount.fileSize);
	}

	writeln(renderTable(data));
}

bool parseArgs(string[] args)
{
	try
	{
		auto helpInformation = getopt(
			args,
			"fileSize|s", "Count file sizes", &appOpt.countFileSize);

		if (helpInformation.helpWanted)
		{
			defaultGetoptPrinter("Simple count lines of code impl by DLang.",
				helpInformation.options);
			return false;
		}
	}
	catch (GetOptException e)
	{
		writeln(e.msg);
		parseArgs([args[0], "--help"]); // @suppress(dscanner.unused_result)
		return false;
	}

	return true;
}

void main(string[] args)
{
	if (!parseArgs(args))
		return;

	writeln(appOpt.countFileSize);
	LangCount*[LangEnum] result;
	foreach (string fileName; dirEntries("./", SpanMode.shallow))
	{
		auto ext = extension(fileName);

		if (ext.empty)
			continue;

		auto lang = extLangMap.get(ext, LangEnum.other);

		if (lang == LangEnum.other)
		{
			continue;
		}

		if (lang !in result)
		{
			auto val = new LangCount();
			val.type = lang;
			result[lang] = val;
		}

		auto val = result[lang];
		auto comments = getLangCommentPrefix(lang);
		bool countingMultiLineComment = false;
		string mutliLineCommentEndChars;
		string content = readText(fileName);
		val.files += 1;

		if (appOpt.countFileSize)
		{
			auto file = File(fileName);
			val.fileSize += file.size();
		}

		foreach (line; splitLines(content))
		{
			val.lines += 1;

			if (!comments.empty)
			{
				foreach (comment; comments)
				{
					if (comment.length == 1)
					{
						if (countingMultiLineComment)
							continue;
						// one line comment
						if (startsWith(stripLeft(line), comment[0]))
						{
							val.comment += 1;
							break;
						}
					}
					else
					{
						// mutli line comments
						if (countingMultiLineComment)
						{
							val.comment += 1;
							if (endsWith(stripLeft(line), mutliLineCommentEndChars))
							{
								countingMultiLineComment = false;
								break;
							}
						}
						else
						{
							if (startsWith(stripLeft(line), comment[0]))
							{
								val.comment += 1;
								countingMultiLineComment = true;
								mutliLineCommentEndChars = comment[1];
								break;
							}
						}
					}
				}
			}
			else if (stripRight(line).empty)
			{
				val.blank += 1;
			}
			else
			{
				val.code += 1;
			}
		}
	}

	printResult(result);
}
