// i18n — Carino Custom Images. English source strings ARE the keys, so a
// missing entry falls back to English. The locale is resolved by the fleet
// file carino-lang.js (?lang > cookie > browser > en), which exposes
// window.CarinoLang.current and fires 'carino:langchange' on switch.
// Deliberately English: code samples, commands, file names, layer/image ids,
// and terms of art (OCI, DE, bootc, VRR, DICOM, PACS, FDA...).
// Fold bodies that mix prose with inline <code>/<b>/<em>/<a> children are
// translated through RICH (per-selector innerHTML) rather than data-i18n.
// Split keys: sentences interrupted by an inline <a>/<b>/<code> are wrapped
// as text fragments; every locale's fragments are written to compose
// grammatically around the fixed child element.

const I18N = {
    es: {
        'Late shift.': 'Turno nocturno.',
        'Good morning.': 'Buenos días.',
        'Good afternoon.': 'Buenas tardes.',
        'Good evening.': 'Buenas noches.',
        // Hero + tabs
        'Another fresh install to configure? It drifts within weeks anyway.': '¿Otra instalación nueva por configurar? Total, en unas semanas ya se ha desviado.',
        'The whole system, set up for your work,': 'Todo el sistema, preparado para tu trabajo,',
        'before you ever boot it.': 'antes siquiera de arrancarlo.',
        'Eight Fedora images: six desktops and two headless appliances. Pick the one that matches what you do — the tools, the drivers and the tuning are already in it, and an update that goes wrong is one command back.': 'Ocho imágenes de Fedora: seis escritorios y dos equipos sin escritorio. Elige la que encaja con lo que haces: las herramientas, los drivers y el ajuste ya vienen dentro, y una actualización que sale mal se revierte con un comando.',
        'Get an image': 'Obtener una imagen',
        'Build it yourself': 'Constrúyela tú mismo',
        // Get pane
        'Editions': 'Ediciones',
        'Based on Fedora 44': 'Basado en Fedora 44',
        'plus two headless appliances': 'más dos equipos sin escritorio',
        'Image-based Fedora — transactional updates, identical on every machine, one-command rollback.': 'Fedora basado en imágenes: actualizaciones transaccionales, idéntico en cada máquina, rollback con un comando.',
        'This is Fedora, not a fork — every package and security update comes from': 'Esto es Fedora, no un fork: cada paquete y actualización de seguridad viene de',
        ", on Fedora's schedule. What this project maintains is the integration: session, kernel arguments, masked services, decided once.": ', según el calendario de Fedora. Lo que este proyecto mantiene es la integración: sesión, argumentos del kernel, servicios enmascarados, decidido una sola vez.',
        'Already installed?': '¿Ya está instalado?',
        'Set up the machine you have instead — Carino Setup configures an existing system across many distributions and desktops, in one command.': 'Configura la máquina que ya tienes: Carino Setup ajusta un sistema existente en muchas distribuciones y escritorios, con un solo comando.',
        'Setup instead': 'Ir a Setup',
        // Build pane
        'Clone the repo and run four commands. Every image is a chain of bootc layers, each an OCI image built from its parent.': 'Clona el repo y ejecuta cuatro comandos. Cada imagen es una cadena de capas bootc, cada una una imagen OCI construida a partir de su padre.',
        'How an image is assembled': 'Cómo se ensambla una imagen',
        'upstream base': 'base upstream',
        'hardening, common CLI tools': 'hardening, herramientas CLI comunes',
        'DE-agnostic desktop infrastructure': 'infraestructura de escritorio independiente del DE',
        'COSMIC + Hyprland sessions': 'sesiones COSMIC + Hyprland',
        'console and SSH, no desktop': 'consola y SSH, sin escritorio',
        'Each layer is an OCI image built': 'Cada capa es una imagen OCI construida con',
        'its parent, so a shared layer is built once and reused by everything below it. The appliance branch skips the desktop entirely. The gold leaves are the published images; intermediates are build infrastructure.': 'sobre su capa padre, así que una capa compartida se construye una sola vez y la reutiliza todo lo que cuelga de ella. La rama de los equipos sin escritorio se salta esa capa por completo. Las hojas doradas son las imágenes publicadas; las intermedias son infraestructura de build.',
        'Four commands — plain bash and podman': 'Cuatro comandos: bash y podman a secas',
        'See the catalog.': 'Mira el catálogo.',
        'Every image with its DE, description and pin reason.': 'Cada imagen con su DE, descripción y motivo de fijación.',
        'Generate Containerfiles.': 'Genera los Containerfiles.',
        'Chain-aware Containerfiles under': 'Containerfiles conscientes de la cadena, en',
        'Build the images.': 'Construye las imágenes.',
        'Each shared layer built once, in dependency order.': 'Cada capa compartida se construye una vez, en orden de dependencias.',
        'Make an ISO.': 'Crea una ISO.',
        'bootc-image-builder (needs': 'bootc-image-builder (requiere',
        // Folds
        'Classic (non-atomic) images — experimental': 'Imágenes clásicas (no atómicas) — experimental',
        'Why only COSMIC and Hyprland?': '¿Por qué solo COSMIC y Hyprland?',
        'Why atomic, and what do updates look like?': '¿Por qué atómico y cómo son las actualizaciones?',
        'The telephony image has no desktop — why?': '¿Por qué la imagen de telefonía no tiene escritorio?',
        'An offline appliance — why is that an image?': '¿Por qué un equipo para trabajar sin internet es una imagen?',
        'Add your own purpose': 'Añade tu propio propósito',
        'Because every desktop shipped is a desktop that has to be verified against every purpose, and the combinations nobody tests are the ones that break. One session, built once, means the integration work — tearing control, per-output VRR, no file indexer, no automounter — is done once and inherited by all six desktop images.': 'Porque cada escritorio incluido es un escritorio que hay que verificar contra cada propósito, y las combinaciones que nadie prueba son las que se rompen. Una sesión, construida una vez, significa que el trabajo de integración — control del tearing, VRR por salida, sin indexador de archivos, sin automontaje — se hace una vez y lo heredan las seis imágenes de escritorio.',
        'Both sessions come from the same layer and the same greeter: pick COSMIC at login for pointer-driven use, or Hyprland when you want tiling. Purposes still declare which session they are pinned to, so adding a second desktop later stays a one-line change rather than a rewrite.': 'Ambas sesiones vienen de la misma capa y el mismo greeter: elige COSMIC al iniciar sesión para uso con puntero, o Hyprland cuando quieras tiling. Cada propósito sigue declarando a qué sesión está fijado, así que añadir un segundo escritorio más adelante es un cambio de una línea, no una reescritura.',
        // Medical modal
        'Regulatory notice': 'Aviso regulatorio',
        'This is not a medical device': 'Esto no es un producto sanitario',
        'The Medical Imaging image bundles a DICOM toolchain and scientific Python for': 'La imagen de Imagen médica incluye una cadena de herramientas DICOM y Python científico para',
        'research, education and PACS tooling': 'investigación, educación y herramientas PACS',
        '. It is': '. No está',
        'not intended for diagnosis': 'pensada para el diagnóstico',
        ', and must not be used to interpret patient studies for clinical decisions.': ' y no debe usarse para interpretar estudios de pacientes en decisiones clínicas.',
        'The long-term goal is a validated, reproducible build suitable for FDA submission — every install running the same image, byte for byte. It has': 'La meta a largo plazo es una build validada y reproducible apta para presentarse ante la FDA: cada instalación ejecutando la misma imagen, byte a byte. No ha sido',
        'not been submitted, reviewed or cleared': 'presentada, revisada ni autorizada',
        'by the FDA or any other regulator.': 'por la FDA ni por ningún otro regulador.',
        'Cancel': 'Cancelar',
        'I understand — proceed': 'Entiendo — continuar',
        // JS-generated chrome
        'Download ISO': 'Descargar ISO',
        'Container': 'Contenedor',
        'Preview coming soon': 'Vista previa próximamente',
        'Not published yet': 'Aún no publicado',
        'Registry pending': 'Registro pendiente',
        'Copied': 'Copiado',
        'I understand — not published yet': 'Entiendo — aún no publicado',
        'I understand — copy command': 'Entiendo — copiar comando',
        'Image preview': 'Vista previa de la imagen',
        // Edition names + descriptions
        'General': 'General',
        'Medical Imaging': 'Imagen médica',
        'Security': 'Seguridad',
        'Gaming': 'Gaming',
        'Music': 'Música',
        'Local LLMs': 'LLMs locales',
        'Telephony': 'Telefonía',
        'Intranet': 'Intranet',
        'Browsing, mail, office and media: Firefox, Thunderbird, LibreOffice, mpv, KeePassXC.': 'Navegación, correo, ofimática y multimedia: Firefox, Thunderbird, LibreOffice, mpv, KeePassXC.',
        'DICOM toolchain and scientific Python: DCMTK, GDCM, pydicom, dcm2niix, ArgyllCMS calibration.': 'Cadena de herramientas DICOM y Python científico: DCMTK, GDCM, pydicom, dcm2niix, calibración ArgyllCMS.',
        'Capture, recon and forensics: Wireshark, nmap, Sleuth Kit, YARA, radare2. No desktop automounter.': 'Captura, reconocimiento y forense: Wireshark, nmap, Sleuth Kit, YARA, radare2. Sin automontaje de escritorio.',
        'Steam, Lutris and Wine with gamescope, MangoHud and GameMode. Tear-free, per-output VRR.': 'Steam, Lutris y Wine con gamescope, MangoHud y GameMode. Sin tearing, VRR por salida.',
        'Ardour, Qtractor, Hydrogen and Carla on a low-latency stack: threadirqs, tuned, no file indexer.': 'Ardour, Qtractor, Hydrogen y Carla sobre una pila de baja latencia: threadirqs, tuned, sin indexador de archivos.',
        'Ollama, llama.cpp, whisper.cpp and ramalama on the leanest session, so the desktop holds least VRAM.': 'Ollama, llama.cpp, whisper.cpp y ramalama en la sesión más ligera, para que el escritorio ocupe la mínima VRAM.',
        'Asterisk with the FreePBX web UI, MariaDB and PHP 8.2. Headless appliance — no desktop at all.': 'Asterisk con la interfaz web de FreePBX, MariaDB y PHP 8.2. Equipo sin escritorio: ningún entorno gráfico.',
        'bind, chrony, Caddy and Kiwix: names, time, trust, packages and content for a LAN with no working WAN.': 'bind, chrony, Caddy y Kiwix: nombres, hora, confianza, paquetes y contenido para una LAN sin salida a internet.',
        // Accessibility labels
        'Section': 'Sección',
        'Layer chain: quay.io/fedora/fedora-bootc:44, then base, which forks into desktop-common and de/cosmic-hyprland carrying the six desktop purposes, and de/headless carrying the pbx and offline appliances': 'Cadena de capas: quay.io/fedora/fedora-bootc:44, luego base, que se bifurca en desktop-common y de/cosmic-hyprland con los seis propósitos de escritorio, y en de/headless con los equipos pbx y offline',
    },
    'pt-BR': {
        'Late shift.': 'Turno da noite.',
        'Good morning.': 'Bom dia.',
        'Good afternoon.': 'Boa tarde.',
        'Good evening.': 'Boa noite.',
        'Another fresh install to configure? It drifts within weeks anyway.': 'Mais uma instalação nova para configurar? Em poucas semanas ela já se desvia mesmo.',
        'The whole system, set up for your work,': 'O sistema inteiro, pronto para o seu trabalho,',
        'before you ever boot it.': 'antes mesmo do primeiro boot.',
        'Eight Fedora images: six desktops and two headless appliances. Pick the one that matches what you do — the tools, the drivers and the tuning are already in it, and an update that goes wrong is one command back.': 'Oito imagens Fedora: seis desktops e dois appliances sem desktop. Escolha a que combina com o que você faz: as ferramentas, os drivers e o ajuste fino já vêm dentro, e uma atualização que dá errado volta com um comando.',
        'Get an image': 'Baixar uma imagem',
        'Build it yourself': 'Construa você mesmo',
        'Editions': 'Edições',
        'Based on Fedora 44': 'Baseado no Fedora 44',
        'plus two headless appliances': 'mais dois appliances sem desktop',
        'Image-based Fedora — transactional updates, identical on every machine, one-command rollback.': 'Fedora baseado em imagens: atualizações transacionais, idêntico em cada máquina, rollback com um comando.',
        'This is Fedora, not a fork — every package and security update comes from': 'Isto é Fedora, não um fork: cada pacote e atualização de segurança vem do',
        ", on Fedora's schedule. What this project maintains is the integration: session, kernel arguments, masked services, decided once.": ', no calendário do Fedora. O que este projeto mantém é a integração: sessão, argumentos de kernel, serviços mascarados, decidido uma única vez.',
        'Already installed?': 'Já instalado?',
        'Set up the machine you have instead — Carino Setup configures an existing system across many distributions and desktops, in one command.': 'Configure a máquina que você já tem: o Carino Setup ajusta um sistema existente em várias distribuições e desktops, com um único comando.',
        'Setup instead': 'Ir para o Setup',
        'Clone the repo and run four commands. Every image is a chain of bootc layers, each an OCI image built from its parent.': 'Clone o repositório e rode quatro comandos. Cada imagem é uma cadeia de camadas bootc, cada uma delas uma imagem OCI construída a partir da camada pai.',
        'How an image is assembled': 'Como uma imagem é montada',
        'upstream base': 'base upstream',
        'hardening, common CLI tools': 'hardening, ferramentas CLI comuns',
        'DE-agnostic desktop infrastructure': 'infraestrutura de desktop independente de DE',
        'COSMIC + Hyprland sessions': 'sessões COSMIC + Hyprland',
        'console and SSH, no desktop': 'console e SSH, sem desktop',
        'Each layer is an OCI image built': 'Cada camada é uma imagem OCI construída com',
        'its parent, so a shared layer is built once and reused by everything below it. The appliance branch skips the desktop entirely. The gold leaves are the published images; intermediates are build infrastructure.': 'a partir da camada pai, então uma camada compartilhada é construída uma vez e reaproveitada por tudo que vem abaixo dela. O ramo do appliance pula o desktop por completo. As folhas douradas são as imagens publicadas; as intermediárias são infraestrutura de build.',
        'Four commands — plain bash and podman': 'Quatro comandos: só bash e podman',
        'See the catalog.': 'Veja o catálogo.',
        'Every image with its DE, description and pin reason.': 'Cada imagem com seu DE, descrição e motivo do pin.',
        'Generate Containerfiles.': 'Gere os Containerfiles.',
        'Chain-aware Containerfiles under': 'Containerfiles cientes da cadeia, em',
        'Build the images.': 'Construa as imagens.',
        'Each shared layer built once, in dependency order.': 'Cada camada compartilhada é construída uma vez, em ordem de dependências.',
        'Make an ISO.': 'Crie uma ISO.',
        'bootc-image-builder (needs': 'bootc-image-builder (requer',
        'Classic (non-atomic) images — experimental': 'Imagens clássicas (não atômicas) — experimental',
        'Why only COSMIC and Hyprland?': 'Por que só COSMIC e Hyprland?',
        'Why atomic, and what do updates look like?': 'Por que atômico, e como são as atualizações?',
        'The telephony image has no desktop — why?': 'Por que a imagem de telefonia não tem desktop?',
        'An offline appliance — why is that an image?': 'Por que um appliance para operar sem internet é uma imagem?',
        'Add your own purpose': 'Adicione seu próprio propósito',
        'Because every desktop shipped is a desktop that has to be verified against every purpose, and the combinations nobody tests are the ones that break. One session, built once, means the integration work — tearing control, per-output VRR, no file indexer, no automounter — is done once and inherited by all six desktop images.': 'Porque cada desktop incluído é um desktop que precisa ser verificado contra cada propósito, e as combinações que ninguém testa são as que quebram. Uma sessão, construída uma vez, significa que o trabalho de integração — controle de tearing, VRR por saída, sem indexador de arquivos, sem montagem automática — é feito uma vez e herdado pelas seis imagens de desktop.',
        'Both sessions come from the same layer and the same greeter: pick COSMIC at login for pointer-driven use, or Hyprland when you want tiling. Purposes still declare which session they are pinned to, so adding a second desktop later stays a one-line change rather than a rewrite.': 'As duas sessões vêm da mesma camada e do mesmo greeter: escolha COSMIC no login para uso com ponteiro, ou Hyprland quando quiser tiling. Cada propósito ainda declara a qual sessão está fixado, então adicionar um segundo desktop depois continua sendo uma mudança de uma linha, não uma reescrita.',
        'Regulatory notice': 'Aviso regulatório',
        'This is not a medical device': 'Isto não é um dispositivo médico',
        'The Medical Imaging image bundles a DICOM toolchain and scientific Python for': 'A imagem de Imagem médica reúne um conjunto de ferramentas DICOM e Python científico para',
        'research, education and PACS tooling': 'pesquisa, educação e ferramentas PACS',
        '. It is': '. Ela',
        'not intended for diagnosis': 'não se destina ao diagnóstico',
        ', and must not be used to interpret patient studies for clinical decisions.': ' e não deve ser usada para interpretar exames de pacientes em decisões clínicas.',
        'The long-term goal is a validated, reproducible build suitable for FDA submission — every install running the same image, byte for byte. It has': 'A meta de longo prazo é um build validado e reproduzível adequado para submissão à FDA: cada instalação executando a mesma imagem, byte a byte. Ele',
        'not been submitted, reviewed or cleared': 'não foi submetido, revisado nem liberado',
        'by the FDA or any other regulator.': 'pela FDA nem por qualquer outro regulador.',
        'Cancel': 'Cancelar',
        'I understand — proceed': 'Entendi — continuar',
        'Download ISO': 'Baixar ISO',
        'Container': 'Contêiner',
        'Preview coming soon': 'Prévia em breve',
        'Not published yet': 'Ainda não publicado',
        'Registry pending': 'Registro pendente',
        'Copied': 'Copiado',
        'I understand — not published yet': 'Entendi — ainda não publicado',
        'I understand — copy command': 'Entendi — copiar comando',
        'Image preview': 'Prévia da imagem',
        'General': 'Geral',
        'Medical Imaging': 'Imagem médica',
        'Security': 'Segurança',
        'Gaming': 'Games',
        'Music': 'Música',
        'Local LLMs': 'LLMs locais',
        'Telephony': 'Telefonia',
        'Intranet': 'Intranet',
        'Browsing, mail, office and media: Firefox, Thunderbird, LibreOffice, mpv, KeePassXC.': 'Navegação, e-mail, escritório e mídia: Firefox, Thunderbird, LibreOffice, mpv, KeePassXC.',
        'DICOM toolchain and scientific Python: DCMTK, GDCM, pydicom, dcm2niix, ArgyllCMS calibration.': 'Ferramentas DICOM e Python científico: DCMTK, GDCM, pydicom, dcm2niix, calibração ArgyllCMS.',
        'Capture, recon and forensics: Wireshark, nmap, Sleuth Kit, YARA, radare2. No desktop automounter.': 'Captura, reconhecimento e forense: Wireshark, nmap, Sleuth Kit, YARA, radare2. Sem montagem automática no desktop.',
        'Steam, Lutris and Wine with gamescope, MangoHud and GameMode. Tear-free, per-output VRR.': 'Steam, Lutris e Wine com gamescope, MangoHud e GameMode. Sem tearing, VRR por saída.',
        'Ardour, Qtractor, Hydrogen and Carla on a low-latency stack: threadirqs, tuned, no file indexer.': 'Ardour, Qtractor, Hydrogen e Carla numa pilha de baixa latência: threadirqs, tuned, sem indexador de arquivos.',
        'Ollama, llama.cpp, whisper.cpp and ramalama on the leanest session, so the desktop holds least VRAM.': 'Ollama, llama.cpp, whisper.cpp e ramalama na sessão mais enxuta, para o desktop ocupar o mínimo de VRAM.',
        'Asterisk with the FreePBX web UI, MariaDB and PHP 8.2. Headless appliance — no desktop at all.': 'Asterisk com a interface web do FreePBX, MariaDB e PHP 8.2. Appliance headless — sem desktop algum.',
        'bind, chrony, Caddy and Kiwix: names, time, trust, packages and content for a LAN with no working WAN.': 'bind, chrony, Caddy e Kiwix: nomes, hora, confiança, pacotes e conteúdo para uma LAN sem saída para a internet.',
        // Accessibility labels
        'Section': 'Seção',
        'Layer chain: quay.io/fedora/fedora-bootc:44, then base, which forks into desktop-common and de/cosmic-hyprland carrying the six desktop purposes, and de/headless carrying the pbx and offline appliances': 'Cadeia de camadas: quay.io/fedora/fedora-bootc:44, depois base, que se bifurca em desktop-common e de/cosmic-hyprland com os seis propósitos de desktop, e em de/headless com os appliances pbx e offline',
    },
    ja: {
        'Late shift.': '夜勤お疲れさま。',
        'Good morning.': 'おはようございます。',
        'Good afternoon.': 'こんにちは。',
        'Good evening.': 'こんばんは。',
        'Another fresh install to configure? It drifts within weeks anyway.': 'また新規インストールの設定から？どうせ数週間で構成は崩れていく。',
        'The whole system, set up for your work,': 'システム全体が、あなたの仕事に合わせて、',
        'before you ever boot it.': '起動する前から整っている。',
        'Eight Fedora images: six desktops and two headless appliances. Pick the one that matches what you do — the tools, the drivers and the tuning are already in it, and an update that goes wrong is one command back.': 'Fedoraイメージは8種類: デスクトップ6つと、デスクトップを持たないアプライアンス2つ。用途に合うものを選ぶだけ — ツール、ドライバー、チューニングは組み込み済み。更新に失敗してもコマンド1つで元に戻せます。',
        'Get an image': 'イメージを入手',
        'Build it yourself': '自分でビルド',
        'Editions': 'エディション',
        'Based on Fedora 44': 'Fedora 44ベース',
        'plus two headless appliances': '＋デスクトップなしのアプライアンス2つ',
        'Image-based Fedora — transactional updates, identical on every machine, one-command rollback.': 'イメージベースのFedora — トランザクショナルな更新、全マシンで同一、コマンド1つでロールバック。',
        'This is Fedora, not a fork — every package and security update comes from': 'これはフォークではなくFedoraそのものです。すべてのパッケージとセキュリティ更新の提供元は',
        ", on Fedora's schedule. What this project maintains is the integration: session, kernel arguments, masked services, decided once.": 'で、スケジュールもFedoraのまま。本プロジェクトが管理するのは統合の部分 — セッション、カーネル引数、サービスのマスク — を一度だけ決めておくことです。',
        'Already installed?': 'インストール済みですか？',
        'Set up the machine you have instead — Carino Setup configures an existing system across many distributions and desktops, in one command.': '手元のマシンをそのまま整えるなら Carino Setup — 多くのディストリビューションとデスクトップに対応し、コマンド1つで既存システムを設定します。',
        'Setup instead': 'Setupへ',
        'Clone the repo and run four commands. Every image is a chain of bootc layers, each an OCI image built from its parent.': 'リポジトリをcloneして4つのコマンドを実行するだけ。各イメージはbootcレイヤーのチェーンで、それぞれ親からビルドされるOCIイメージです。',
        'How an image is assembled': 'イメージの組み立て方',
        'upstream base': 'アップストリームのベース',
        'hardening, common CLI tools': 'ハードニング、共通CLIツール',
        'DE-agnostic desktop infrastructure': 'DE非依存のデスクトップ基盤',
        'COSMIC + Hyprland sessions': 'COSMIC + Hyprlandセッション',
        'console and SSH, no desktop': 'コンソールとSSH、デスクトップなし',
        'Each layer is an OCI image built': '各レイヤーは親イメージを',
        'its parent, so a shared layer is built once and reused by everything below it. The appliance branch skips the desktop entirely. The gold leaves are the published images; intermediates are build infrastructure.': 'で参照して構築されるOCIイメージなので、共有レイヤーは一度だけビルドされ、その下のすべてで再利用されます。アプライアンスの枝はデスクトップを完全に省きます。金色の葉が公開イメージで、中間レイヤーはビルド用の基盤です。',
        'Four commands — plain bash and podman': '4つのコマンド — 素のbashとpodmanだけ',
        'See the catalog.': 'カタログを見る。',
        'Every image with its DE, description and pin reason.': '各イメージのDE、説明、固定理由を一覧表示。',
        'Generate Containerfiles.': 'Containerfileを生成する。',
        'Chain-aware Containerfiles under': 'チェーン対応のContainerfileの出力先:',
        'Build the images.': 'イメージをビルドする。',
        'Each shared layer built once, in dependency order.': '共有レイヤーは依存順に一度だけビルドされます。',
        'Make an ISO.': 'ISOを作る。',
        'bootc-image-builder (needs': 'bootc-image-builder (要',
        'Classic (non-atomic) images — experimental': 'クラシック（非アトミック）イメージ — 実験的',
        'Why only COSMIC and Hyprland?': 'なぜCOSMICとHyprlandだけ？',
        'Why atomic, and what do updates look like?': 'なぜアトミック？更新はどうなる？',
        'The telephony image has no desktop — why?': '電話交換機イメージにデスクトップが無いのはなぜ？',
        'An offline appliance — why is that an image?': 'オフライン運用のアプライアンスが、なぜイメージなのか？',
        'Add your own purpose': '独自の用途を追加',
        'Because every desktop shipped is a desktop that has to be verified against every purpose, and the combinations nobody tests are the ones that break. One session, built once, means the integration work — tearing control, per-output VRR, no file indexer, no automounter — is done once and inherited by all six desktop images.': '搭載するデスクトップが増えるほど、すべての用途との組み合わせ検証が必要になり、誰もテストしない組み合わせこそが壊れます。一度だけ作った1つのセッションなら、統合作業 — ティアリング制御、出力ごとのVRR、ファイルインデクサーなし、オートマウンターなし — を一度で済ませ、6つのデスクトップイメージすべてが継承します。',
        'Both sessions come from the same layer and the same greeter: pick COSMIC at login for pointer-driven use, or Hyprland when you want tiling. Purposes still declare which session they are pinned to, so adding a second desktop later stays a one-line change rather than a rewrite.': 'どちらのセッションも同じレイヤーと同じグリーターから提供されます。ポインター操作ならログイン時にCOSMICを、タイリングが欲しければHyprlandを選ぶだけ。各用途はどのセッションに固定されているかを宣言し続けるので、後から2つ目のデスクトップを足すのも書き直しではなく1行の変更で済みます。',
        'Regulatory notice': '規制に関する注意',
        'This is not a medical device': 'これは医療機器ではありません',
        'The Medical Imaging image bundles a DICOM toolchain and scientific Python for': '医用画像イメージにはDICOMツールチェーンと科学計算用Pythonが含まれ、その対象は',
        'research, education and PACS tooling': '研究・教育・PACSツール',
        '. It is': 'です。',
        'not intended for diagnosis': '診断用途は想定されておらず',
        ', and must not be used to interpret patient studies for clinical decisions.': '、臨床判断のために患者の検査を読影する目的で使用してはなりません。',
        'The long-term goal is a validated, reproducible build suitable for FDA submission — every install running the same image, byte for byte. It has': '長期的な目標は、FDA申請に耐える検証済みで再現可能なビルドです — すべてのインストールがバイト単位で同一のイメージを実行します。現時点では',
        'not been submitted, reviewed or cleared': '申請も審査も承認も',
        'by the FDA or any other regulator.': 'FDAを含むいかなる規制当局からも受けていません。',
        'Cancel': 'キャンセル',
        'I understand — proceed': '理解しました — 続行',
        'Download ISO': 'ISOをダウンロード',
        'Container': 'コンテナ',
        'Preview coming soon': 'プレビューは近日公開',
        'Not published yet': '未公開です',
        'Registry pending': 'レジストリ準備中',
        'Copied': 'コピーしました',
        'I understand — not published yet': '理解しました — 未公開です',
        'I understand — copy command': '理解しました — コマンドをコピー',
        'Image preview': 'イメージのプレビュー',
        'General': '一般',
        'Medical Imaging': '医用画像',
        'Security': 'セキュリティ',
        'Gaming': 'ゲーミング',
        'Music': '音楽',
        'Local LLMs': 'ローカルLLM',
        'Telephony': '電話交換機',
        'Intranet': 'イントラネット',
        'Browsing, mail, office and media: Firefox, Thunderbird, LibreOffice, mpv, KeePassXC.': 'ブラウジング、メール、オフィス、メディア: Firefox、Thunderbird、LibreOffice、mpv、KeePassXC。',
        'DICOM toolchain and scientific Python: DCMTK, GDCM, pydicom, dcm2niix, ArgyllCMS calibration.': 'DICOMツールチェーンと科学計算用Python: DCMTK、GDCM、pydicom、dcm2niix、ArgyllCMSキャリブレーション。',
        'Capture, recon and forensics: Wireshark, nmap, Sleuth Kit, YARA, radare2. No desktop automounter.': 'キャプチャ、偵察、フォレンジック: Wireshark、nmap、Sleuth Kit、YARA、radare2。デスクトップのオートマウントなし。',
        'Steam, Lutris and Wine with gamescope, MangoHud and GameMode. Tear-free, per-output VRR.': 'Steam、Lutris、Wineにgamescope、MangoHud、GameModeを同梱。ティアリングなし、出力ごとのVRR。',
        'Ardour, Qtractor, Hydrogen and Carla on a low-latency stack: threadirqs, tuned, no file indexer.': '低レイテンシ構成のArdour、Qtractor、Hydrogen、Carla: threadirqs、tuned、ファイルインデクサーなし。',
        'Ollama, llama.cpp, whisper.cpp and ramalama on the leanest session, so the desktop holds least VRAM.': '最小構成のセッションにOllama、llama.cpp、whisper.cpp、ramalama。デスクトップのVRAM占有を最小に。',
        'Asterisk with the FreePBX web UI, MariaDB and PHP 8.2. Headless appliance — no desktop at all.': 'AsteriskとFreePBXのWeb UI、MariaDB、PHP 8.2。デスクトップを一切持たないヘッドレスアプライアンス。',
        'bind, chrony, Caddy and Kiwix: names, time, trust, packages and content for a LAN with no working WAN.': 'bind、chrony、Caddy、Kiwix: 外部回線の無いLANに、名前・時刻・信頼・パッケージ・コンテンツを供給。',
        // Accessibility labels
        'Section': 'セクション',
        'Layer chain: quay.io/fedora/fedora-bootc:44, then base, which forks into desktop-common and de/cosmic-hyprland carrying the six desktop purposes, and de/headless carrying the pbx and offline appliances': 'レイヤーチェーン: quay.io/fedora/fedora-bootc:44、次に base。そこから desktop-common と de/cosmic-hyprland（6つのデスクトップ用途）と、de/headless（pbx と offline のアプライアンス）に分岐します',
    },
    ru: {
        'Late shift.': 'Ночная смена.',
        'Good morning.': 'Доброе утро.',
        'Good afternoon.': 'Добрый день.',
        'Good evening.': 'Добрый вечер.',
        'Another fresh install to configure? It drifts within weeks anyway.': 'Опять настраивать свежую установку? Всё равно через пару недель она «поплывёт».',
        'The whole system, set up for your work,': 'Вся система, настроенная под вашу работу,',
        'before you ever boot it.': 'ещё до первой загрузки.',
        'Eight Fedora images: six desktops and two headless appliances. Pick the one that matches what you do — the tools, the drivers and the tuning are already in it, and an update that goes wrong is one command back.': 'Восемь образов Fedora: шесть рабочих столов и два сервера без рабочего стола. Выберите тот, что соответствует вашим задачам: инструменты, драйверы и тюнинг уже внутри, а неудачное обновление откатывается одной командой.',
        'Get an image': 'Получить образ',
        'Build it yourself': 'Соберите сами',
        'Editions': 'Редакции',
        'Based on Fedora 44': 'На основе Fedora 44',
        'plus two headless appliances': 'плюс два сервера без рабочего стола',
        'Image-based Fedora — transactional updates, identical on every machine, one-command rollback.': 'Fedora на основе образов: транзакционные обновления, идентичность на каждой машине, откат одной командой.',
        'This is Fedora, not a fork — every package and security update comes from': 'Это Fedora, а не форк: каждый пакет и каждое обновление безопасности приходит из',
        ", on Fedora's schedule. What this project maintains is the integration: session, kernel arguments, masked services, decided once.": ' — по графику Fedora. Этот проект поддерживает лишь интеграцию: сессию, аргументы ядра, маскированные сервисы — решённые один раз.',
        'Already installed?': 'Уже установлено?',
        'Set up the machine you have instead — Carino Setup configures an existing system across many distributions and desktops, in one command.': 'Настройте машину, которая у вас уже есть: Carino Setup конфигурирует существующую систему на множестве дистрибутивов и рабочих столов одной командой.',
        'Setup instead': 'Перейти в Setup',
        'Clone the repo and run four commands. Every image is a chain of bootc layers, each an OCI image built from its parent.': 'Склонируйте репозиторий и выполните четыре команды. Каждый образ — цепочка bootc-слоёв, каждый из которых является OCI-образом, собранным от родителя.',
        'How an image is assembled': 'Как собирается образ',
        'upstream base': 'базовый upstream-образ',
        'hardening, common CLI tools': 'усиление защиты, общие CLI-инструменты',
        'DE-agnostic desktop infrastructure': 'десктоп-инфраструктура, не зависящая от DE',
        'COSMIC + Hyprland sessions': 'сессии COSMIC + Hyprland',
        'console and SSH, no desktop': 'консоль и SSH, без рабочего стола',
        'Each layer is an OCI image built': 'Каждый слой — OCI-образ, собранный через',
        'its parent, so a shared layer is built once and reused by everything below it. The appliance branch skips the desktop entirely. The gold leaves are the published images; intermediates are build infrastructure.': 'от родительского, поэтому общий слой собирается один раз и переиспользуется всем, что лежит ниже него. Ветка серверов без рабочего стола обходит его полностью. Золотые листья — публикуемые образы; промежуточные слои — инфраструктура сборки.',
        'Four commands — plain bash and podman': 'Четыре команды — обычные bash и podman',
        'See the catalog.': 'Посмотрите каталог.',
        'Every image with its DE, description and pin reason.': 'Каждый образ с его DE, описанием и причиной закрепления.',
        'Generate Containerfiles.': 'Сгенерируйте файлы Containerfile.',
        'Chain-aware Containerfiles under': 'Containerfile с учётом цепочки — в каталоге',
        'Build the images.': 'Соберите образы.',
        'Each shared layer built once, in dependency order.': 'Каждый общий слой собирается один раз, в порядке зависимостей.',
        'Make an ISO.': 'Создайте ISO.',
        'bootc-image-builder (needs': 'bootc-image-builder (нужен',
        'Classic (non-atomic) images — experimental': 'Классические (неатомарные) образы — экспериментально',
        'Why only COSMIC and Hyprland?': 'Почему только COSMIC и Hyprland?',
        'Why atomic, and what do updates look like?': 'Почему атомарность и как выглядят обновления?',
        'The telephony image has no desktop — why?': 'Почему у телефонного образа нет рабочего стола?',
        'An offline appliance — why is that an image?': 'Почему сервер для работы без интернета — это образ?',
        'Add your own purpose': 'Добавьте своё назначение',
        'Because every desktop shipped is a desktop that has to be verified against every purpose, and the combinations nobody tests are the ones that break. One session, built once, means the integration work — tearing control, per-output VRR, no file indexer, no automounter — is done once and inherited by all six desktop images.': 'Потому что каждый включённый рабочий стол нужно проверять с каждым назначением, а ломаются именно те комбинации, которые никто не тестирует. Одна сессия, собранная один раз, означает, что вся интеграция — контроль tearing, VRR на каждый выход, без индексатора файлов, без автомонтирования — делается однажды и наследуется всеми шестью образами с рабочим столом.',
        'Both sessions come from the same layer and the same greeter: pick COSMIC at login for pointer-driven use, or Hyprland when you want tiling. Purposes still declare which session they are pinned to, so adding a second desktop later stays a one-line change rather than a rewrite.': 'Обе сессии происходят из одного слоя и одного экрана входа: выберите COSMIC для работы с мышью или Hyprland, если нужен тайлинг. Каждое назначение по-прежнему объявляет, к какой сессии оно закреплено, поэтому добавить второй рабочий стол позже — изменение в одну строку, а не переписывание.',
        'Regulatory notice': 'Нормативное уведомление',
        'This is not a medical device': 'Это не медицинское изделие',
        'The Medical Imaging image bundles a DICOM toolchain and scientific Python for': 'Образ «Медицинская визуализация» включает инструменты DICOM и научный Python для',
        'research, education and PACS tooling': 'исследований, обучения и PACS-инструментов',
        '. It is': '. Он',
        'not intended for diagnosis': 'не предназначен для диагностики',
        ', and must not be used to interpret patient studies for clinical decisions.': ' и не должен использоваться для интерпретации исследований пациентов при принятии клинических решений.',
        'The long-term goal is a validated, reproducible build suitable for FDA submission — every install running the same image, byte for byte. It has': 'Долгосрочная цель — валидированная, воспроизводимая сборка, пригодная для подачи в FDA: каждая установка выполняет один и тот же образ, байт в байт. Он',
        'not been submitted, reviewed or cleared': 'не подавался, не проверялся и не одобрялся',
        'by the FDA or any other regulator.': 'ни FDA, ни каким-либо другим регулятором.',
        'Cancel': 'Отмена',
        'I understand — proceed': 'Понимаю — продолжить',
        'Download ISO': 'Скачать ISO',
        'Container': 'Контейнер',
        'Preview coming soon': 'Превью скоро появится',
        'Not published yet': 'Ещё не опубликовано',
        'Registry pending': 'Реестр ещё не готов',
        'Copied': 'Скопировано',
        'I understand — not published yet': 'Понимаю — ещё не опубликовано',
        'I understand — copy command': 'Понимаю — скопировать команду',
        'Image preview': 'Предпросмотр образа',
        'General': 'Общий',
        'Medical Imaging': 'Медицинская визуализация',
        'Security': 'Безопасность',
        'Gaming': 'Игры',
        'Music': 'Музыка',
        'Local LLMs': 'Локальные LLM',
        'Telephony': 'Телефония',
        'Intranet': 'Интранет',
        'Browsing, mail, office and media: Firefox, Thunderbird, LibreOffice, mpv, KeePassXC.': 'Браузер, почта, офис и медиа: Firefox, Thunderbird, LibreOffice, mpv, KeePassXC.',
        'DICOM toolchain and scientific Python: DCMTK, GDCM, pydicom, dcm2niix, ArgyllCMS calibration.': 'Инструменты DICOM и научный Python: DCMTK, GDCM, pydicom, dcm2niix, калибровка ArgyllCMS.',
        'Capture, recon and forensics: Wireshark, nmap, Sleuth Kit, YARA, radare2. No desktop automounter.': 'Захват трафика, разведка и форензика: Wireshark, nmap, Sleuth Kit, YARA, radare2. Без автомонтирования на рабочем столе.',
        'Steam, Lutris and Wine with gamescope, MangoHud and GameMode. Tear-free, per-output VRR.': 'Steam, Lutris и Wine с gamescope, MangoHud и GameMode. Без разрывов кадра, VRR на каждый выход.',
        'Ardour, Qtractor, Hydrogen and Carla on a low-latency stack: threadirqs, tuned, no file indexer.': 'Ardour, Qtractor, Hydrogen и Carla на стеке с низкой задержкой: threadirqs, tuned, без индексатора файлов.',
        'Ollama, llama.cpp, whisper.cpp and ramalama on the leanest session, so the desktop holds least VRAM.': 'Ollama, llama.cpp, whisper.cpp и ramalama в самой лёгкой сессии, чтобы рабочий стол занимал минимум VRAM.',
        'Asterisk with the FreePBX web UI, MariaDB and PHP 8.2. Headless appliance — no desktop at all.': 'Asterisk с веб-интерфейсом FreePBX, MariaDB и PHP 8.2. Сервер без рабочего стола — графики нет вовсе.',
        'bind, chrony, Caddy and Kiwix: names, time, trust, packages and content for a LAN with no working WAN.': 'bind, chrony, Caddy и Kiwix: имена, время, доверие, пакеты и контент для сети без выхода в интернет.',
        // Accessibility labels
        'Section': 'Раздел',
        'Layer chain: quay.io/fedora/fedora-bootc:44, then base, which forks into desktop-common and de/cosmic-hyprland carrying the six desktop purposes, and de/headless carrying the pbx and offline appliances': 'Цепочка слоёв: quay.io/fedora/fedora-bootc:44, затем base, который разветвляется на desktop-common с de/cosmic-hyprland (шесть назначений с рабочим столом) и на de/headless с образами pbx и offline',
    },
};

// Rich blocks: fold paragraphs that mix prose with inline <code>/<b>/<em>/<a>
// children, which the textContent-based data-i18n mechanism cannot carry.
// Keyed by CSS selector; values are the full innerHTML per locale (English is
// restored from a snapshot captured on the first pass). Inline tags, commands,
// file names and links mirror the English markup exactly.
const RICH = {
    '#fold-bp-1': {
        es: '<code>./build.sh blueprint IMAGE</code> aplana toda la cadena de capas de una imagen en un blueprint de osbuild para el backend clásico de Workstation. Es una <b>exportación, no una vía de construcción</b> — aquí nada resuelve dependencias ni la construye, así que se la pasas tú mismo a <code>composer-cli</code>:',
        'pt-BR': '<code>./build.sh blueprint IMAGE</code> achata toda a cadeia de camadas de uma imagem em um blueprint do osbuild para o backend clássico do Workstation. É uma <b>exportação, não um caminho de build</b> — nada aqui resolve dependências nem constrói, então você mesmo entrega ao <code>composer-cli</code>:',
        ja: '<code>./build.sh blueprint IMAGE</code> は、イメージのレイヤーチェーン全体を従来の Workstation バックエンド向けの osbuild ブループリントに平坦化します。これは<b>エクスポートであり、ビルド経路ではありません</b> — 依存解決もビルドもここでは行わないため、<code>composer-cli</code> には自分で渡します:',
        ru: '<code>./build.sh blueprint IMAGE</code> сводит всю цепочку слоёв образа в blueprint для osbuild под классический бэкенд Workstation. Это <b>экспорт, а не путь сборки</b> — здесь ничто не разрешает зависимости и не собирает, так что вы сами передаёте его в <code>composer-cli</code>:',
    },
    '#fold-bp-2': {
        es: 'Un blueprint es una copia <b>con pérdidas</b>, nunca un equivalente. Los paquetes de COPR necesitan el repositorio configurado en el anfitrión o falla la resolución de dependencias; los Flatpaks, los archivos estáticos y los scripts de post-instalación se pierden; y un servicio cuya unidad solo existe en el árbol de archivos de la propia imagen se omite de <code>enabled</code>, porque osbuild ejecuta <code>systemctl enable</code> durante la construcción y una unidad ausente la hace fallar. Cada omisión se lista en la cabecera del TOML y se avisa en la terminal.',
        'pt-BR': 'Um blueprint é uma cópia <b>com perdas</b>, nunca um equivalente. Pacotes do COPR precisam do repositório configurado no host ou a resolução de dependências falha; Flatpaks, arquivos estáticos e scripts de pós-instalação são descartados; e um serviço cuja unit existe apenas na árvore de arquivos da própria imagem é omitido de <code>enabled</code>, porque o osbuild executa <code>systemctl enable</code> durante o build e uma unit ausente o faz falhar. Cada omissão é listada no cabeçalho do TOML e avisada no terminal.',
        ja: 'ブループリントは<b>非可逆</b>なコピーであり、同等物ではありません。COPR のパッケージはホスト側でリポジトリを設定しないと依存解決に失敗します。Flatpak、静的ファイル、ポストインストールスクリプトは失われます。また、ユニットがイメージ自身のファイルツリーにしかないサービスは <code>enabled</code> から除外されます — osbuild はビルド中に <code>systemctl enable</code> を実行するため、ユニットが無いとビルドが失敗するからです。省略された項目はすべて TOML のヘッダーに記載され、端末にも警告が出ます。',
        ru: 'Blueprint — это копия <b>с потерями</b>, а не эквивалент. Пакетам из COPR нужен репозиторий, настроенный на стороне хоста, иначе разрешение зависимостей падает; Flatpak-и, статические файлы и пост-установочные скрипты отбрасываются; а служба, unit-файл которой лежит только в файловом дереве самого образа, исключается из <code>enabled</code>, потому что osbuild выполняет <code>systemctl enable</code> во время сборки и отсутствующий unit её ломает. Все пропуски перечислены в заголовке TOML и выводятся предупреждением в терминал.',
    },
    '#fold-pbx-1': {
        es: 'Una centralita es un equipo, no un puesto de trabajo: se administra por su interfaz web y por SSH, y nadie se sienta delante. Por eso <code>carino-pbx</code> se fija a la sesión <code>headless</code>, que sale de <code>base</code> y nunca toca <code>desktop-common</code>: sin Wayland, sin PipeWire, sin portales, sin Flatpak, sin navegador. Menos paquetes que parchear en la única máquina del edificio que contesta al teléfono.',
        'pt-BR': 'Um PBX é um appliance, não uma estação de trabalho: você o acessa pela interface web e por SSH, e ninguém senta na frente dele. Por isso <code>carino-pbx</code> fixa a sessão <code>headless</code>, que sai de <code>base</code> e nunca toca <code>desktop-common</code> — sem Wayland, sem PipeWire, sem portais, sem Flatpak, sem navegador. Menos pacotes para corrigir na única máquina do prédio que atende o telefone.',
        ja: '電話交換機はワークステーションではなくアプライアンスです。操作はWeb UIとSSHで行い、誰も前に座りません。そのため <code>carino-pbx</code> は <code>headless</code> セッションに固定され、<code>base</code> から分岐して <code>desktop-common</code> には一切触れません — Wayland も PipeWire も、ポータルも Flatpak もブラウザもありません。建物の中で電話に応答する唯一のマシンで、修正すべきパッケージが減ります。',
        ru: 'АТС — это сервер, а не рабочая станция: к ней обращаются через веб-интерфейс и по SSH, и перед ней никто не сидит. Поэтому <code>carino-pbx</code> закреплён за сессией <code>headless</code>, которая ответвляется от <code>base</code> и вообще не касается <code>desktop-common</code>: ни Wayland, ни PipeWire, ни порталов, ни Flatpak, ни браузера. Меньше пакетов, которые нужно обновлять на единственной машине в здании, отвечающей на звонки.',
    },
    '#fold-pbx-2': {
        es: 'Una advertencia dicha con claridad: <b>FreePBX no forma parte de la imagen.</b> Escribe en <code>/var</code>, y una imagen bootc copia <code>/var</code> a la máquina una sola vez, en la instalación, y nunca más — así que incluirlo lo congelaría en la versión con la que instalaste. La imagen trae Asterisk, MariaDB, Apache y el runtime PHP 8.2 que FreePBX exige como RPMs que <em>sí</em> se actualizan de forma transaccional, y FreePBX se instala solo en el primer arranque y luego se actualiza con <code>fwconsole ma upgradeall</code>. <code>bootc rollback</code> cubre el sistema operativo de debajo; no revierte una actualización de módulos de FreePBX.',
        'pt-BR': 'Uma ressalva dita com todas as letras: <b>o FreePBX não faz parte da imagem.</b> Ele escreve em <code>/var</code>, e uma imagem bootc copia <code>/var</code> para a máquina uma única vez, na instalação, e nunca mais — então embuti-lo o congelaria na versão com que você instalou. A imagem traz Asterisk, MariaDB, Apache e o runtime PHP 8.2 que o FreePBX exige como RPMs que <em>de fato</em> se atualizam de forma transacional, e o FreePBX se instala sozinho no primeiro boot e depois se atualiza com <code>fwconsole ma upgradeall</code>. O <code>bootc rollback</code> cobre o sistema operacional embaixo; ele não desfaz uma atualização de módulos do FreePBX.',
        ja: '注意点をはっきり書いておきます: <b>FreePBX 自体はイメージに含まれません。</b> FreePBX は <code>/var</code> に書き込みますが、bootc イメージの <code>/var</code> がマシンにコピーされるのはインストール時の一度きりで、以降は更新されません — 焼き込めば、最初にインストールしたときのバージョンで固定されてしまいます。イメージには Asterisk、MariaDB、Apache、そして FreePBX が要求する PHP 8.2 ランタイムが、トランザクショナルに<em>更新される</em> RPM として入っています。FreePBX は初回起動時に自分自身をインストールし、以後は <code>fwconsole ma upgradeall</code> で更新します。<code>bootc rollback</code> が戻せるのは下地の OS であり、FreePBX のモジュール更新は戻せません。',
        ru: 'Одна оговорка прямым текстом: <b>сам FreePBX не входит в образ.</b> Он пишет в <code>/var</code>, а bootc-образ копирует <code>/var</code> на машину один раз при установке и больше никогда — так что вшитый FreePBX застыл бы на версии того образа, с которого вы ставились. В образе есть Asterisk, MariaDB, Apache и требуемый FreePBX рантайм PHP 8.2 в виде RPM, которые <em>действительно</em> обновляются транзакционно, а FreePBX ставит себя сам при первой загрузке и дальше обновляется через <code>fwconsole ma upgradeall</code>. <code>bootc rollback</code> откатывает ОС под ним, но не откатывает обновление модулей FreePBX.',
    },
    '#fold-offline-1': {
        es: '<code>carino-offline</code> es la piedra angular de la intranet: la única máquina de la que una LAN sin salida a internet sigue obteniendo nombres, hora, confianza, paquetes y contenido. Se fija a la misma sesión <code>headless</code> que <code>carino-pbx</code>, porque es «un equipo que tiene que responder en los puertos de la propia LAN antes de que nada más en la red esté levantado: DNS, NTP y HTTP son sus interfaces y SSH es su consola». El plan del que esta máquina es una pieza está escrito en <a href="https://offline.carino.systems/" target="_blank" rel="noopener">offline.carino.systems</a>, y esa página apunta de vuelta aquí.',
        'pt-BR': '<code>carino-offline</code> é a pedra angular da intranet: a única máquina de onde uma LAN sem saída para a internet ainda tira nomes, hora, confiança, pacotes e conteúdo. Ela fixa a mesma sessão <code>headless</code> que o <code>carino-pbx</code>, porque é "um appliance que precisa responder nas portas da própria LAN antes de qualquer outra coisa na rede subir: DNS, NTP e HTTP são suas interfaces e o SSH é seu console". O plano do qual esta máquina é uma peça está escrito em <a href="https://offline.carino.systems/" target="_blank" rel="noopener">offline.carino.systems</a>, e aquela página aponta de volta para cá.',
        ja: '<code>carino-offline</code> はイントラネットの要石です。外部回線が使えないLANが、それでも名前・時刻・信頼・パッケージ・コンテンツを受け取れる唯一の一台です。<code>carino-pbx</code> と同じ <code>headless</code> セッションに固定されているのは、これが「ネットワーク上の他の何よりも先に、LAN自身のポートで応答しなければならないアプライアンス。DNS、NTP、HTTP がそのインターフェースであり、SSH がコンソール」だからです。この一台が組み込まれる全体の計画は <a href="https://offline.carino.systems/" target="_blank" rel="noopener">offline.carino.systems</a> にまとめてあり、そちらからもここへ戻るリンクがあります。',
        ru: '<code>carino-offline</code> — краеугольный камень интранета: та единственная машина, от которой сеть без работающего внешнего канала по-прежнему получает имена, время, доверие, пакеты и контент. Она закреплена за той же сессией <code>headless</code>, что и <code>carino-pbx</code>, потому что это «сервер, который должен отвечать на собственных портах локальной сети раньше, чем поднимется всё остальное: DNS, NTP и HTTP — его интерфейсы, а SSH — его консоль». План, частью которого является эта машина, описан на <a href="https://offline.carino.systems/" target="_blank" rel="noopener">offline.carino.systems</a>, и та страница ссылается обратно сюда.',
    },
    '#fold-offline-2': {
        es: 'Es una imagen y no una lista de paquetes de Carino Setup porque cinco de sus decisiones son integración de sistema que un script posterior a la instalación no puede asumir. Hay que quitarle el puerto 53 a <code>systemd-resolved</code>, que en esta base viene instalado y habilitado por preset, así que se <b>enmascara</b> en vez de deshabilitarse — y <code>/etc/resolv.conf</code>, que ahí es un enlace simbólico al directorio de ejecución de resolved, hay que reasignarlo en el mismo movimiento o la máquina se queda sin ningún resolutor. Una CA interna necesita un directorio de anclas donde la raíz del sitio aterrice de verdad, con <code>update-ca-trust extract</code> ejecutado donde surte efecto. <code>dnf</code> tiene que poder apuntar a un mirror de la LAN sin que las herramientas de paquetes de la propia máquina se queden bloqueadas en un nombre que quizá no resuelva. Y chrony tiene que seguir sirviendo la hora sin nada upstream alcanzable, lo que exige una directiva cuya ausencia pasa desapercibida durante semanas. <b>Nada de esta imagen se ha arrancado todavía</b>: el conjunto de paquetes se resolvió contra Fedora 44 y esos datos del sistema se leyeron dentro de la capa headless ya construida, pero no se ha instalado ninguna ISO.',
        'pt-BR': 'É uma imagem, e não uma lista de pacotes do Carino Setup, porque cinco de suas decisões são integração de sistema que um script rodado depois da instalação não tem como assumir. A porta 53 precisa ser tirada do <code>systemd-resolved</code>, que nesta base vem instalado e habilitado por preset, então ele é <b>mascarado</b> em vez de desabilitado — e o <code>/etc/resolv.conf</code>, que ali é um link simbólico para o diretório de execução do resolved, precisa ser reassumido no mesmo movimento, ou a máquina fica sem resolvedor nenhum. Uma CA interna precisa de um diretório de âncoras onde a raiz do site realmente caia, com <code>update-ca-trust extract</code> executado onde faz efeito. O <code>dnf</code> precisa poder apontar para um espelho na LAN sem travar as ferramentas de pacote da própria máquina em um nome que talvez não resolva. E o chrony precisa continuar servindo hora sem nenhuma fonte upstream alcançável, o que exige uma diretiva cuja ausência fica silenciosa por semanas. <b>Nada desta imagem foi inicializado ainda</b>: o conjunto de pacotes foi resolvido contra o Fedora 44 e esses fatos do sistema foram lidos dentro da camada headless já construída, mas nenhuma ISO foi instalada.',
        ja: 'これが Carino Setup のパッケージ一覧ではなくイメージである理由は、5つの決定が、インストール後に走るスクリプトでは引き受けられないシステム統合だからです。ポート53は <code>systemd-resolved</code> から取り上げる必要があります。このベースでは systemd-resolved がインストール済みかつ preset で有効化されているため、無効化ではなく<b>マスク</b>します。さらに <code>/etc/resolv.conf</code> はそこでは resolved の実行時ディレクトリへのシンボリックリンクなので、同時に付け替えないとリゾルバーが一つも無い状態になります。内部CAには、サイトのルート証明書が実際に置かれるアンカーディレクトリと、効果のある場所で実行される <code>update-ca-trust extract</code> が要ります。<code>dnf</code> は、解決できるとは限らないホスト名でこの箱自身のパッケージ処理を止めることなく、LAN上のミラーへ向けられる必要があります。そして chrony は、上流が一つも届かない状態でも時刻を配り続けなければならず、それには、無くても何週間も表に出ないディレクティブが1行必要です。<b>このイメージはまだ一度も起動していません</b> — パッケージ構成は Fedora 44 に対して解決し、これらのシステム上の事実はビルド済みの headless レイヤーの中で確認しましたが、ISO のインストールは行っていません。',
        ru: 'Это образ, а не список пакетов для Carino Setup, потому что пять его решений — системная интеграция, которую скрипт, запускаемый после установки, взять на себя не может. Порт 53 приходится отбирать у <code>systemd-resolved</code>, который на этой базе установлен и включён пресетом, поэтому он <b>маскируется</b>, а не отключается — а <code>/etc/resolv.conf</code>, который там является символической ссылкой в рабочий каталог resolved, нужно переприсвоить тем же движением, иначе у машины не остаётся резолвера вообще. Внутреннему УЦ нужен каталог якорей, куда корневой сертификат площадки действительно попадает, и <code>update-ca-trust extract</code>, выполненный там, где это даёт эффект. <code>dnf</code> должен уметь смотреть на зеркало в локальной сети, не подвешивая собственный пакетный инструментарий машины на имени, которое может не разрешиться. А chrony должен продолжать раздавать время, когда наверху не доступно ничего, и для этого нужна директива, отсутствие которой молчит неделями. <b>Ничего из этого образа ещё не загружалось</b>: набор пакетов разрешён против Fedora 44, а эти системные факты прочитаны внутри уже собранного слоя headless, но ни один ISO не устанавливался.',
    },
    '#fold-atomic-1': {
        es: 'El valor de un sistema hecho a propósito está en la <em>integración</em> — parámetros del kernel, enmascarado de servicios, configuración de la sesión — y en un sistema mutable esa integración se va desviando. Con bootc todo el sistema operativo es una única imagen versionada: cada instalación es idéntica, las actualizaciones son transaccionales y una que sale mal está a un <code>bootc rollback</code> de distancia.',
        'pt-BR': 'O valor de um sistema feito sob medida está na <em>integração</em> — parâmetros do kernel, mascaramento de serviços, configuração da sessão — e em um sistema mutável essa integração se desfaz com o tempo. Com o bootc todo o sistema operacional é uma única imagem versionada: cada instalação é idêntica, as atualizações são transacionais e uma que deu errado está a um <code>bootc rollback</code> de distância.',
        ja: '目的別システムの価値は<em>統合</em>にあります — カーネル引数、サービスのマスク、セッション設定 — そして可変なシステムでは、その統合が時間とともに崩れていきます。bootc では OS 全体がバージョン管理された 1 つのイメージです。どのインストールも同一で、更新はトランザクショナル、失敗した更新は <code>bootc rollback</code> ひとつで戻せます。',
        ru: 'Ценность системы, собранной под задачу, — в <em>интеграции</em>: параметры ядра, маскирование служб, настройка сессии. На изменяемой системе эта интеграция со временем расползается. С bootc вся ОС — один версионированный образ: каждая установка идентична, обновления транзакционные, а неудачное откатывается одной командой <code>bootc rollback</code>.',
    },
    '#fold-own-1': {
        es: 'Crea un solo archivo, <code>config/purposes/&lt;name&gt;.conf</code> — bash plano, incluido por el sistema de construcción. Cuatro campos son obligatorios, el resto son opcionales:',
        'pt-BR': 'Crie um único arquivo, <code>config/purposes/&lt;name&gt;.conf</code> — bash puro, carregado pelo sistema de build. Quatro campos são obrigatórios, o resto é opcional:',
        ja: 'ファイルを 1 つ作るだけです。<code>config/purposes/&lt;name&gt;.conf</code> — ビルドシステムが読み込む素の bash です。必須のフィールドは 4 つ、残りは任意です:',
        ru: 'Создайте один файл — <code>config/purposes/&lt;name&gt;.conf</code>, обычный bash, который подключает система сборки. Четыре поля обязательны, остальные необязательны:',
    },
    '#fold-own-2': {
        es: 'El catálogo se deriva escaneando <code>config/purposes/*.conf</code>, así que <code>./build.sh list</code> lo recoge de inmediato. Todo lo que es «solo una lista de paquetes» para un sistema <em>ya instalado</em> vive en <a href="https://setup.carino.systems/">Carino Setup</a>.',
        'pt-BR': 'O catálogo é derivado da varredura de <code>config/purposes/*.conf</code>, então <code>./build.sh list</code> o reconhece na hora. Tudo que é "apenas uma lista de pacotes" para um sistema <em>já instalado</em> fica no <a href="https://setup.carino.systems/">Carino Setup</a>.',
        ja: 'カタログは <code>config/purposes/*.conf</code> を走査して生成されるため、<code>./build.sh list</code> はすぐに認識します。<em>インストール済み</em>のシステムにとって「ただのパッケージ一覧」でしかないものは、代わりに <a href="https://setup.carino.systems/">Carino Setup</a> にあります。',
        ru: 'Каталог получается сканированием <code>config/purposes/*.conf</code>, поэтому <code>./build.sh list</code> подхватывает его сразу. Всё, что для <em>уже установленной</em> системы является «просто списком пакетов», живёт в <a href="https://setup.carino.systems/">Carino Setup</a>.',
    },
};

function currentFleetLang() { return (window.CarinoLang && window.CarinoLang.current) || 'en'; }

function t(key) {
    const dict = I18N[currentFleetLang()];
    return (dict && dict[key]) || key;
}

// Static markup: elements carrying data-i18n use their original English text
// as the key (captured on first pass so locale switches stay reversible).
function applyStaticI18n() {
    document.querySelectorAll('[data-i18n]').forEach((el) => {
        if (!el.dataset.i18nKey) el.dataset.i18nKey = el.textContent.trim();
        el.textContent = t(el.dataset.i18nKey);
    });
}

// Rich blocks: snapshot the original English innerHTML once, then swap the
// whole innerHTML per locale (en restores the snapshot).
function applyRichI18n() {
    const loc = currentFleetLang();
    Object.keys(RICH).forEach((sel) => {
        const el = document.querySelector(sel);
        if (!el) return;
        if (el.dataset.i18nRich === undefined) el.dataset.i18nRich = el.innerHTML;
        el.innerHTML = (RICH[sel][loc]) || el.dataset.i18nRich;
    });
}

// Prominent attributes, addressed explicitly rather than via data-i18n.
function applyAttrI18n() {
    const pv = document.getElementById('pv');
    if (pv) pv.setAttribute('aria-label', t('Image preview'));
    const tabs = document.querySelector('.tabbar[role="tablist"]');
    if (tabs) tabs.setAttribute('aria-label', t('Section'));
    const chain = document.querySelector('.chain[role="img"]');
    if (chain) chain.setAttribute('aria-label', t('Layer chain: quay.io/fedora/fedora-bootc:44, then base, which forks into desktop-common and de/cosmic-hyprland carrying the six desktop purposes, and de/headless carrying the pbx and offline appliances'));
}

function applyI18n() {
    document.documentElement.lang = currentFleetLang();
    applyStaticI18n();
    applyRichI18n();
    applyAttrI18n();
    // The picker/preview are JS-built with tr()-wrapped literals; rebuild them
    // so they pick up the new locale. Best-effort — guarded so the static page
    // still translates even if the inline script changed or failed.
    try {
        if (typeof renderPicker === 'function' && typeof setPreview === 'function') {
            renderPicker();
            const shown = current; // globals shared with the inline script
            if (shown) { current = null; setPreview(shown); }
        }
    } catch (e) { /* dynamic chrome keeps its previous language */ }
}

// carino-lang.js and this file are both deferred (this one after it), so
// CarinoLang is resolved by the time DOMContentLoaded fires.
document.addEventListener('DOMContentLoaded', applyI18n);
window.addEventListener('carino:langchange', applyI18n);
