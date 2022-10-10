# loc
Simple count lines of code impl by DLang.

Features:
- sort by comment/code...
- multi line comments
- count file size


## Run
```
git clone https://github.com/alluLinger/loc
cd loc
dub run -- -f -s=code
```

![screen](https://user-images.githubusercontent.com/21037233/194888455-9837217d-6729-463c-994f-9938c3403099.png)

## TODO
- [ ] improve speed
- [ ] add unitest

## Options
```
-f --fileSize Count file sizes
-s --sort Result sort by --sort=file/code/comment/blank/lines/fileSize
```

## Supported Language
- [x] d
- [x] cpp
- [x] go
- [x] rust
- [x] bash
- [x] python
- [x] ruby
- [x] java
- [x] markDown
- [x] html
- [x] yaml
- [x] json
- [x] javaScript
- [x] typeScript
