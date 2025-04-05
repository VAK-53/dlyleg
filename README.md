# Dlyleg

DOT → leex → yeek → {libgraph; ETS} → graph

Заголовок настоящей статьи расшифровывается как реализация на платформе Elixir транслятора описания графа на языке dot при помощи генераторов лексера и парсера leex и yeek в структуру графа пакета libgraph. Название пакета dlyleg является акронимом из первых букв использованных компонентов:

dot,
leek,
yeek,
libgraph + ETS

Для транслятора, или десериализатора,  используется БНФ языка DOT, который взят из официального руководства на сайте graphviz. Из  правил выкинуты синтаксические категории, связанные с портом, и пока не учитываются subgraph.

На нынешнем этапе был принят "эстафетный" вариант доступ к внутренней структуре Libgraph.Graph под влиянием решений в пакете Graphvix.
Это оптимальный вариант для задач типа простого конвертора и на нем удобно строить конвейеры. Вот как выглядит конвейера обработки первичного файла dot до стадии обратного преобразования в файл dot:

read |> lex |> pars |> covert |> toDot

Входные файлы загружаются из каталога priv на уровне проекта или указываются по абсолюному пути.
В будущем есть план испробовать вариант создания GenServer OTP, содержащего структуру graph, для более развитых архитектур.

Для хранения атрибутов графа, его узлов и рёбер используется отдельная таблица ETS. Это связано с ограничением пакета libgraph. В настоящей версии конвертора содержимое таблицы ETS на диске не сохраняется. Это планируется сделать после того, как будет решен вопрос идентичности загружаемых связанных файлов атрибутов и графа.

На предпоследнем этапе конвертации проводится проверка соответствия названий атрибутов элементам графа стандартным именам.
Провероочные функций названия атрибутов реализованы с помощью макросов Elixir на базе трех таблиц csv. Таблицы располагаются в каталоге priv подпроекта leg. Типы значений атрибутов не проверяются.

Атрибутика графа и его элементов может служить основой для DSL языка прикладной области и каждый желающий может расширять список допустимых атрибутов.

Для быстрого освоения конветора в зрнтичный проект пакета dlyleg встроен подпроект Example, который содержит типовые технологические конвейеры разной степени сложности.

Надеюсь, что за мной последуют и другие специалисты прикладных областей.

