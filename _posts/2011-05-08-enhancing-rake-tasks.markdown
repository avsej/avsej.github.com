---
layout: post
title: Обновление rake-тасков
description: Удобный способ расширения существующих rake-тасков
---

В одном проекте мне понадобился [ragel][1] для разбора формул из TeX и, так как проект является гемом с нативной библиотекой, он должен ещё компилироваться при установке. Для облегчения сборки я использую [rake-compiler][2], который предоставляет набор тасков для сборки каждого расширения + таск `compile`, что бы собрать все сразу. Проблема была в том, чтобы встроить в эту цепочку ещё один мини-таск, который бы генерировал парсер из ragel-исходника.

Одни для этого [создают отдельные таски][3] как gherkin, а другие -- [используют gnu makefile][4] как unicorn. Мне оба способа показались громоздкими, к тому же у меня уже есть таск `compile` и заводить ещё один, который будет вызывать `ragel`, а потом `compile` было бы слишком. В [документации rake][5] нашлась отличный метод `Task#enhance`, позволяющий добавить зависимости в уже существующий таск, но для меня этого было недостаточно, потому что, судя по коду, он добавляет таск в конец цепочки зависимостей, а мне нужно сгенерировать парсер _перед_ компиляцией. Выход нашёлся сразу же: использовать `Task#prerequisites` (который ведёт себя как массив) и просто добавить мой мини-таск в самое начало. Ниже то, что получилось в итоге:

    require 'rake/extensiontask'
    Rake::ExtensionTask.new('expression_ext')
    rule 'ext/expression_ext/parser.c' => 'ext/expression_ext/parser.c.rl' do |task|
      sh %{ragel -C -o #{task.name} #{task.source}}
    end
    Rake::Task['compile'].prerequisites.unshift('ext/expression_ext/parser.c')

Ссылки
------

1. [Ragel state machine compiler](http://www.complang.org/ragel)
2. [rake-compiler](https://github.com/luislavena/rake-compiler)

[1]: http://www.complang.org/ragel
[2]: https://github.com/luislavena/rake-compiler
[3]: https://github.com/aslakhellesoy/gherkin/blob/master/tasks/ragel_task.rb#L13
[4]: https://github.com/defunkt/unicorn/blob/master/GNUmakefile#L58
[5]: http://rake.rubyforge.org/classes/Rake/Task.html#M000112
