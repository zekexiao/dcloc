import std.stdio;
import std.file;
import std.string;
import std.range;
import std.path;

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
}

string getLangCommentPrefix(LangEnum lang)
{
	switch (lang)
	{
	case LangEnum.markDown:
	case LangEnum.html:
		return "<!--";
	case LangEnum.bash:
	case LangEnum.python:
	case LangEnum.ruby:
	case LangEnum.yaml:
		return "#";
	default:
		return "//";
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
}

void main()
{
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
		auto comment = getLangCommentPrefix(lang);
		string content = readText(fileName);
		val.files += 1;

		foreach (line; splitLines(content))
		{
			val.lines += 1;

			if (startsWith(stripLeft(line), comment))
			{
				val.comment += 1;
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

	writeln("Lang", "\t", "File", "\t", "Code", "\t", "Comment", "\t", "Blank", "\t", "Lines");
	foreach (val; result)
	{
		writeln(val.type, "\t", val.files, "\t", val.code, "\t", val.comment, "\t", val.blank, "\t", val
				.lines);
	}
}
