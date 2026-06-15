import Foundation

struct AppInterfaceStrings: Equatable {
    let language: AppLanguage

    init(language: AppLanguage) {
        self.language = language
    }

    var startVoiceInput: String { labels.startVoiceInput }
    var chooseModeAndStart: String { labels.chooseModeAndStart }
    var settingsAndAPI: String { labels.settingsAndAPI }
    var interfaceLanguage: String { labels.interfaceLanguage }
    var quitSpeakMore: String { labels.quitSpeakMore }
    var settingsWindowTitle: String { phrase(.settingsWindowTitle) }
    var settingsSubtitle: String { phrase(.settingsSubtitle) }
    var save: String { phrase(.save) }
    var saved: String { phrase(.saved) }
    var defaultBehavior: String { phrase(.defaultBehavior) }
    var defaultBehaviorSubtitle: String { phrase(.defaultBehaviorSubtitle) }
    var translationTarget: String { phrase(.translationTarget) }
    var polishIntensity: String { phrase(.polishIntensity) }
    var shortcutSettings: String { phrase(.shortcutSettings) }
    var shortcutSettingsSubtitle: String { phrase(.shortcutSettingsSubtitle) }
    var triggerStyle: String { phrase(.triggerStyle) }
    var voiceInputShortcut: String { phrase(.voiceInputShortcut) }
    var recordShortcut: String { phrase(.recordShortcut) }
    var recordingShortcut: String { phrase(.recordingShortcut) }
    var shortcutRecorderHint: String { phrase(.shortcutRecorderHint) }
    var invalidShortcut: String { phrase(.invalidShortcut) }
    var speechRecognition: String { phrase(.speechRecognition) }
    var speechRecognitionSubtitle: String { phrase(.speechRecognitionSubtitle) }
    var speechService: String { phrase(.speechService) }
    var textAI: String { phrase(.textAI) }
    var textAISubtitle: String { phrase(.textAISubtitle) }
    var aiService: String { phrase(.aiService) }
    var advancedSettings: String { phrase(.advancedSettings) }
    var appearanceAndPermissions: String { phrase(.appearanceAndPermissions) }
    var appearanceAndPermissionsSubtitle: String { phrase(.appearanceAndPermissionsSubtitle) }
    var tutorial: String { phrase(.tutorial) }
    var tutorialSubtitle: String { phrase(.tutorialSubtitle) }
    var reopenTutorial: String { phrase(.reopenTutorial) }
    var saveHistory: String { phrase(.saveHistory) }
    var launchAtLogin: String { phrase(.launchAtLogin) }
    var comingAfterPackaging: String { phrase(.comingAfterPackaging) }
    var apiSetup: String { phrase(.apiSetup) }
    var apiSetupDescription: String { phrase(.apiSetupDescription) }
    var openAliyun: String { phrase(.openAliyun) }
    var openSiliconFlow: String { phrase(.openSiliconFlow) }
    var modelLabel: String { phrase(.modelLabel) }
    var endpoint: String { phrase(.endpoint) }
    var close: String { phrase(.close) }
    var cancel: String { phrase(.cancel) }
    var shortcutHint: String { phrase(.shortcutHint) }
    var readyMessage: String { phrase(.readyMessage) }
    var listeningMessage: String { phrase(.listeningMessage) }
    var finalizingMessage: String { phrase(.finalizingMessage) }
    var transformingMessage: String { phrase(.transformingMessage) }
    var insertingMessage: String { phrase(.insertingMessage) }
    var noSpeechMessage: String { phrase(.noSpeechMessage) }
    var failedMessage: String { phrase(.failedMessage) }
    var openAccessibilitySettings: String { phrase(.openAccessibilitySettings) }
    var openModelSettings: String { phrase(.openModelSettings) }
    var speechAPIKeyPlaceholder: String { phrase(.speechAPIKeyPlaceholder) }
    var speechModelPlaceholder: String { phrase(.speechModelPlaceholder) }
    var speechEndpointPlaceholder: String { phrase(.speechEndpointPlaceholder) }
    var textAPIKeyPlaceholder: String { phrase(.textAPIKeyPlaceholder) }
    var textModelPlaceholder: String { phrase(.textModelPlaceholder) }
    var textEndpointPlaceholder: String { phrase(.textEndpointPlaceholder) }
    var permissions: String { phrase(.permissions) }
    var microphone: String { phrase(.microphone) }
    var accessibility: String { phrase(.accessibility) }
    var openMicrophonePermission: String { phrase(.openMicrophonePermission) }
    var openAccessibilityPermission: String { phrase(.openAccessibilityPermission) }
    var permissionAllowed: String { phrase(.permissionAllowed) }
    var permissionDenied: String { phrase(.permissionDenied) }
    var permissionNotAsked: String { phrase(.permissionNotAsked) }
    var permissionUnknown: String { phrase(.permissionUnknown) }
    var unableToSaveSpeechAPIKey: String { phrase(.unableToSaveSpeechAPIKey) }
    var unableToSaveTextAPIKey: String { phrase(.unableToSaveTextAPIKey) }

    func languageTitle(_ language: AppLanguage) -> String {
        switch language {
        case .system:
            labels.followSystem
        case .simplifiedChinese:
            "简体中文"
        default:
            language.title
        }
    }

    func modeTitle(_ mode: SpeakMoreMode) -> String {
        switch mode {
        case .auto: labels.autoMode
        case .dictate: labels.dictateMode
        case .translate: labels.translateMode
        case .polish: labels.polishMode
        case .askSelectedText: labels.askSelectedTextMode
        }
    }

    func modeSubtitle(_ mode: SpeakMoreMode) -> String {
        LocalizedPhrases.modeSubtitle(mode, language: resolvedLanguage)
    }

    func polishIntensityTitle(_ intensity: TextPolishIntensity) -> String {
        LocalizedPhrases.polishIntensityTitle(intensity, language: resolvedLanguage)
    }

    func polishIntensitySubtitle(_ intensity: TextPolishIntensity) -> String {
        LocalizedPhrases.polishIntensitySubtitle(intensity, language: resolvedLanguage)
    }

    func voiceInputShortcutTriggerTitle(_ trigger: VoiceInputShortcutTrigger) -> String {
        LocalizedPhrases.voiceInputShortcutTriggerTitle(trigger, language: resolvedLanguage)
    }

    func speechRecognitionProviderTitle(_ provider: SpeechRecognitionProviderKind) -> String {
        LocalizedPhrases.speechRecognitionProviderTitle(provider, language: resolvedLanguage)
    }

    func textAIProviderTitle(_ provider: TextAIProviderKind) -> String {
        LocalizedPhrases.textAIProviderTitle(provider, language: resolvedLanguage)
    }

    func audioQualityHint(_ issue: AudioQualityIssue) -> String {
        LocalizedPhrases.audioQualityHint(issue, language: resolvedLanguage)
    }

    func audioQualityMeterTitle(_ kind: AudioQualityMeterKind) -> String {
        LocalizedPhrases.audioQualityMeterTitle(kind, language: resolvedLanguage)
    }

    func statusPresentation(status: SpeakMoreSessionStatus) -> (
        buttonTitle: String,
        menuStatusTitle: String,
        toolTip: String,
        canCancel: Bool
    ) {
        let statusLabels = labels.statusLabels(for: status)
        return (
            "\(AppBrand.englishName) · \(statusLabels.shortTitle)",
            "\(labels.statusPrefix)\(statusLabels.menuTitle)",
            statusLabels.toolTip,
            statusLabels.canCancel
        )
    }

    private var labels: Labels {
        Labels(language: resolvedLanguage)
    }

    private var resolvedLanguage: AppLanguage {
        switch language {
        case .system:
            let preferredLanguage = Locale.preferredLanguages.first?.lowercased() ?? ""
            if preferredLanguage.hasPrefix("zh") { return .simplifiedChinese }
            if preferredLanguage.hasPrefix("ja") { return .japanese }
            if preferredLanguage.hasPrefix("ko") { return .korean }
            if preferredLanguage.hasPrefix("fr") { return .french }
            if preferredLanguage.hasPrefix("de") { return .german }
            if preferredLanguage.hasPrefix("es") { return .spanish }
            if preferredLanguage.hasPrefix("pt") { return .portuguese }
            if preferredLanguage.hasPrefix("it") { return .italian }
            if preferredLanguage.hasPrefix("ru") { return .russian }
            if preferredLanguage.hasPrefix("ar") { return .arabic }
            if preferredLanguage.hasPrefix("hi") { return .hindi }
            if preferredLanguage.hasPrefix("id") { return .indonesian }
            if preferredLanguage.hasPrefix("vi") { return .vietnamese }
            if preferredLanguage.hasPrefix("th") { return .thai }
            return .english
        default:
            return language
        }
    }

    private func phrase(_ key: PhraseKey) -> String {
        LocalizedPhrases.value(for: key, language: resolvedLanguage)
    }
}

private enum PhraseKey {
    case settingsWindowTitle
    case settingsSubtitle
    case save
    case saved
    case defaultBehavior
    case defaultBehaviorSubtitle
    case translationTarget
    case polishIntensity
    case shortcutSettings
    case shortcutSettingsSubtitle
    case triggerStyle
    case voiceInputShortcut
    case recordShortcut
    case recordingShortcut
    case shortcutRecorderHint
    case invalidShortcut
    case speechRecognition
    case speechRecognitionSubtitle
    case speechService
    case textAI
    case textAISubtitle
    case aiService
    case advancedSettings
    case appearanceAndPermissions
    case appearanceAndPermissionsSubtitle
    case tutorial
    case tutorialSubtitle
    case reopenTutorial
    case saveHistory
    case launchAtLogin
    case comingAfterPackaging
    case apiSetup
    case apiSetupDescription
    case openAliyun
    case openSiliconFlow
    case modelLabel
    case endpoint
    case close
    case cancel
    case shortcutHint
    case readyMessage
    case listeningMessage
    case finalizingMessage
    case transformingMessage
    case insertingMessage
    case noSpeechMessage
    case failedMessage
    case openAccessibilitySettings
    case openModelSettings
    case speechAPIKeyPlaceholder
    case speechModelPlaceholder
    case speechEndpointPlaceholder
    case textAPIKeyPlaceholder
    case textModelPlaceholder
    case textEndpointPlaceholder
    case permissions
    case microphone
    case accessibility
    case openMicrophonePermission
    case openAccessibilityPermission
    case permissionAllowed
    case permissionDenied
    case permissionNotAsked
    case permissionUnknown
    case unableToSaveSpeechAPIKey
    case unableToSaveTextAPIKey
}

private enum LocalizedPhrases {
    static func value(for key: PhraseKey, language: AppLanguage) -> String {
        switch key {
        case .settingsWindowTitle:
            return pick(language, zh: "\(AppBrand.englishName) 设置", en: "\(AppBrand.englishName) Settings", ja: "\(AppBrand.englishName) 設定", ko: "\(AppBrand.englishName) 설정", fr: "Réglages \(AppBrand.englishName)", de: "\(AppBrand.englishName)-Einstellungen", es: "Ajustes de \(AppBrand.englishName)", pt: "Configurações do \(AppBrand.englishName)", it: "Impostazioni \(AppBrand.englishName)", ru: "Настройки \(AppBrand.englishName)", ar: "إعدادات \(AppBrand.englishName)", hi: "\(AppBrand.englishName) सेटिंग्स", id: "Pengaturan \(AppBrand.englishName)", vi: "Cài đặt \(AppBrand.englishName)", th: "การตั้งค่า \(AppBrand.englishName)")
        case .settingsSubtitle:
            return pick(language, zh: "\(AppBrand.chineseName)：配置语音输入、AI 整理、快捷输入体验和系统权限。", en: "\(AppBrand.chineseName): Configure voice input, AI refinement, shortcuts, and permissions.", ja: "\(AppBrand.chineseName)：音声入力、AI 整理、ショートカット、権限を設定します。", ko: "\(AppBrand.chineseName): 음성 입력, AI 정리, 단축키와 권한을 설정합니다.", fr: "\(AppBrand.chineseName) : configurez la saisie vocale, l'IA, les raccourcis et les autorisations.", de: "\(AppBrand.chineseName): Spracheingabe, KI-Überarbeitung, Kurzbefehle und Berechtigungen einrichten.", es: "\(AppBrand.chineseName): configura voz, IA, atajos y permisos.", pt: "\(AppBrand.chineseName): configure voz, IA, atalhos e permissões.", it: "\(AppBrand.chineseName): configura voce, IA, scorciatoie e permessi.", ru: "\(AppBrand.chineseName): настройте голосовой ввод, ИИ, горячие клавиши и разрешения.", ar: "\(AppBrand.chineseName): اضبط الإدخال الصوتي والذكاء الاصطناعي والاختصارات والأذونات.", hi: "\(AppBrand.chineseName): वॉइस इनपुट, AI, शॉर्टकट और अनुमतियाँ सेट करें.", id: "\(AppBrand.chineseName): atur input suara, AI, pintasan, dan izin.", vi: "\(AppBrand.chineseName): cấu hình giọng nói, AI, phím tắt và quyền.", th: "\(AppBrand.chineseName): ตั้งค่าเสียง AI ทางลัด และสิทธิ์")
        case .save:
            return pick(language, zh: "保存", en: "Save", ja: "保存", ko: "저장", fr: "Enregistrer", de: "Speichern", es: "Guardar", pt: "Salvar", it: "Salva", ru: "Сохранить", ar: "حفظ", hi: "सहेजें", id: "Simpan", vi: "Lưu", th: "บันทึก")
        case .saved:
            return pick(language, zh: "已保存", en: "Saved", ja: "保存しました", ko: "저장됨", fr: "Enregistré", de: "Gespeichert", es: "Guardado", pt: "Salvo", it: "Salvato", ru: "Сохранено", ar: "تم الحفظ", hi: "सहेजा गया", id: "Tersimpan", vi: "Đã lưu", th: "บันทึกแล้ว")
        case .defaultBehavior:
            return pick(language, zh: "默认行为", en: "Default Behavior", ja: "既定の動作", ko: "기본 동작", fr: "Comportement par défaut", de: "Standardverhalten", es: "Comportamiento predeterminado", pt: "Comportamento padrão", it: "Comportamento predefinito", ru: "Поведение по умолчанию", ar: "السلوك الافتراضي", hi: "डिफ़ॉल्ट व्यवहार", id: "Perilaku Default", vi: "Hành vi mặc định", th: "พฤติกรรมเริ่มต้น")
        case .defaultBehaviorSubtitle:
            return pick(language, zh: "设置按住 Control 后的默认处理方式。", en: "Set what happens after holding Control.", ja: "Control を押した後の既定の処理を設定します。", ko: "Control을 누른 뒤 기본 처리를 설정합니다.", fr: "Définissez l'action après avoir maintenu Control.", de: "Legen Sie fest, was nach Control-Halten passiert.", es: "Define qué ocurre al mantener Control.", pt: "Defina o que acontece ao segurar Control.", it: "Imposta cosa accade tenendo premuto Control.", ru: "Настройте действие после удержания Control.", ar: "حدد ما يحدث بعد الضغط على Control.", hi: "Control दबाने के बाद की कार्रवाई सेट करें.", id: "Atur tindakan setelah menahan Control.", vi: "Đặt hành động sau khi giữ Control.", th: "ตั้งค่าสิ่งที่จะเกิดขึ้นหลังจากกด Control ค้าง")
        case .translationTarget:
            return pick(language, zh: "翻译目标", en: "Translation Target", ja: "翻訳先", ko: "번역 대상", fr: "Langue cible", de: "Zielsprache", es: "Idioma destino", pt: "Idioma de destino", it: "Lingua di destinazione", ru: "Целевой язык", ar: "لغة الترجمة", hi: "अनुवाद लक्ष्य", id: "Target Terjemahan", vi: "Ngôn ngữ đích", th: "ภาษาเป้าหมาย")
        case .polishIntensity:
            return pick(language, zh: "整理强度", en: "Refinement Strength", ja: "整理の強さ", ko: "정리 강도", fr: "Intensité de retouche", de: "Überarbeitungsstärke", es: "Intensidad de mejora", pt: "Intensidade de refinamento", it: "Intensità di rifinitura", ru: "Сила обработки", ar: "قوة التحسين", hi: "सुधार स्तर", id: "Kekuatan Perapian", vi: "Mức chỉnh sửa", th: "ระดับการปรับข้อความ")
        case .shortcutSettings:
            return pick(language, zh: "快捷键", en: "Shortcuts", ja: "ショートカット", ko: "단축키", fr: "Raccourcis", de: "Kurzbefehle", es: "Atajos", pt: "Atalhos", it: "Scorciatoie", ru: "Горячие клавиши", ar: "الاختصارات", hi: "शॉर्टकट", id: "Pintasan", vi: "Phím tắt", th: "ปุ่มลัด")
        case .shortcutSettingsSubtitle:
            return pick(language, zh: "设置如何呼出语音输入。默认仍然是长按 Control。", en: "Set how voice input is invoked. The default remains holding Control.", ja: "音声入力の呼び出し方法を設定します。既定は Control 長押しです。", ko: "음성 입력 호출 방식을 설정합니다. 기본값은 Control 길게 누르기입니다.", fr: "Définissez comment lancer la saisie vocale. Par défaut : maintenir Control.", de: "Legt fest, wie Spracheingabe gestartet wird. Standard bleibt Control halten.", es: "Define cómo activar la voz. El valor predeterminado sigue siendo mantener Control.", pt: "Defina como iniciar a voz. O padrão continua sendo segurar Control.", it: "Imposta come avviare la voce. Il predefinito resta tenere Control.", ru: "Настройте запуск голосового ввода. По умолчанию удерживайте Control.", ar: "حدد كيفية تشغيل الإدخال الصوتي. الافتراضي هو الضغط المطول على Control.", hi: "वॉइस इनपुट कैसे शुरू हो, सेट करें. डिफ़ॉल्ट Control दबाकर रखना है.", id: "Atur cara memulai suara. Default tetap menahan Control.", vi: "Đặt cách gọi nhập giọng nói. Mặc định vẫn là giữ Control.", th: "ตั้งค่าวิธีเรียกใช้เสียง ค่าเริ่มต้นคือกด Control ค้าง")
        case .triggerStyle:
            return pick(language, zh: "触发方式", en: "Trigger", ja: "起動方式", ko: "실행 방식", fr: "Déclencheur", de: "Auslöser", es: "Activación", pt: "Acionamento", it: "Attivazione", ru: "Запуск", ar: "طريقة التشغيل", hi: "ट्रिगर", id: "Pemicu", vi: "Cách kích hoạt", th: "วิธีเรียกใช้")
        case .voiceInputShortcut:
            return pick(language, zh: "呼出快捷键", en: "Voice Shortcut", ja: "音声ショートカット", ko: "음성 단축키", fr: "Raccourci vocal", de: "Sprachkurzbefehl", es: "Atajo de voz", pt: "Atalho de voz", it: "Scorciatoia voce", ru: "Голосовая клавиша", ar: "اختصار الصوت", hi: "वॉइस शॉर्टकट", id: "Pintasan suara", vi: "Phím tắt giọng nói", th: "ปุ่มลัดเสียง")
        case .recordShortcut:
            return pick(language, zh: "录制快捷键", en: "Record Shortcut", ja: "ショートカットを記録", ko: "단축키 녹화", fr: "Enregistrer", de: "Kurzbefehl aufnehmen", es: "Grabar atajo", pt: "Gravar atalho", it: "Registra scorciatoia", ru: "Записать", ar: "تسجيل الاختصار", hi: "शॉर्टकट रिकॉर्ड करें", id: "Rekam pintasan", vi: "Ghi phím tắt", th: "บันทึกปุ่มลัด")
        case .recordingShortcut:
            return pick(language, zh: "按下新的快捷键…", en: "Press new shortcut…", ja: "新しいショートカットを押す…", ko: "새 단축키를 누르세요…", fr: "Appuyez sur le nouveau raccourci…", de: "Neuen Kurzbefehl drücken…", es: "Pulsa el nuevo atajo…", pt: "Pressione o novo atalho…", it: "Premi la nuova scorciatoia…", ru: "Нажмите новое сочетание…", ar: "اضغط الاختصار الجديد…", hi: "नया शॉर्टकट दबाएँ…", id: "Tekan pintasan baru…", vi: "Nhấn phím tắt mới…", th: "กดปุ่มลัดใหม่…")
        case .shortcutRecorderHint:
            return pick(language, zh: "可录制 Control、Control + Option、Control + Space 等。普通按键需要搭配修饰键。", en: "You can record Control, Control + Option, Control + Space, and similar shortcuts. Regular keys need a modifier.", ja: "Control、Control + Option、Control + Space などを記録できます。通常キーには修飾キーが必要です。", ko: "Control, Control + Option, Control + Space 등을 기록할 수 있습니다. 일반 키는 보조키가 필요합니다.", fr: "Vous pouvez enregistrer Control, Control + Option, Control + Space. Les touches simples exigent un modificateur.", de: "Sie können Control, Control + Option, Control + Space aufnehmen. Normale Tasten brauchen eine Zusatztaste.", es: "Puedes grabar Control, Control + Option, Control + Space. Las teclas normales necesitan modificador.", pt: "Você pode gravar Control, Control + Option, Control + Space. Teclas comuns precisam de modificador.", it: "Puoi registrare Control, Control + Option, Control + Space. I tasti normali richiedono un modificatore.", ru: "Можно записать Control, Control + Option, Control + Space. Обычные клавиши требуют модификатора.", ar: "يمكن تسجيل Control أو Control + Option أو Control + Space. المفاتيح العادية تحتاج مفتاح تعديل.", hi: "Control, Control + Option, Control + Space जैसे शॉर्टकट रिकॉर्ड हो सकते हैं. सामान्य कुंजी के साथ modifier चाहिए.", id: "Anda dapat merekam Control, Control + Option, Control + Space. Tombol biasa perlu modifier.", vi: "Có thể ghi Control, Control + Option, Control + Space. Phím thường cần phím bổ trợ.", th: "บันทึก Control, Control + Option, Control + Space ได้ ปุ่มทั่วไปต้องมีปุ่มเสริม")
        case .invalidShortcut:
            return pick(language, zh: "请至少包含一个修饰键。", en: "Include at least one modifier key.", ja: "少なくとも1つの修飾キーを含めてください。", ko: "보조키를 하나 이상 포함하세요.", fr: "Incluez au moins une touche modificatrice.", de: "Mindestens eine Zusatztaste verwenden.", es: "Incluye al menos una tecla modificadora.", pt: "Inclua ao menos uma tecla modificadora.", it: "Includi almeno un tasto modificatore.", ru: "Добавьте хотя бы одну клавишу-модификатор.", ar: "أضف مفتاح تعديل واحداً على الأقل.", hi: "कम से कम एक modifier कुंजी शामिल करें.", id: "Sertakan minimal satu tombol modifier.", vi: "Cần ít nhất một phím bổ trợ.", th: "ต้องมีปุ่มเสริมอย่างน้อยหนึ่งปุ่ม")
        case .speechRecognition:
            return pick(language, zh: "语音识别", en: "Speech Recognition", ja: "音声認識", ko: "음성 인식", fr: "Reconnaissance vocale", de: "Spracherkennung", es: "Reconocimiento de voz", pt: "Reconhecimento de voz", it: "Riconoscimento vocale", ru: "Распознавание речи", ar: "التعرف على الكلام", hi: "वॉइस पहचान", id: "Pengenalan Suara", vi: "Nhận dạng giọng nói", th: "การรู้จำเสียง")
        case .speechRecognitionSubtitle:
            return pick(language, zh: "负责把你的语音实时转成文字。", en: "Turns your speech into text in real time.", ja: "音声をリアルタイムで文字に変換します。", ko: "음성을 실시간으로 텍스트로 변환합니다.", fr: "Transforme votre voix en texte en temps réel.", de: "Wandelt Sprache in Echtzeit in Text um.", es: "Convierte tu voz en texto en tiempo real.", pt: "Converte sua voz em texto em tempo real.", it: "Trasforma la voce in testo in tempo reale.", ru: "Преобразует речь в текст в реальном времени.", ar: "يحوّل كلامك إلى نص في الوقت الفعلي.", hi: "आपकी आवाज़ को रीयल टाइम में टेक्स्ट बनाता है.", id: "Mengubah suara menjadi teks secara real time.", vi: "Chuyển giọng nói thành văn bản theo thời gian thực.", th: "เปลี่ยนเสียงเป็นข้อความแบบเรียลไทม์")
        case .speechService:
            return pick(language, zh: "语音服务", en: "Speech Service", ja: "音声サービス", ko: "음성 서비스", fr: "Service vocal", de: "Sprachdienst", es: "Servicio de voz", pt: "Serviço de voz", it: "Servizio vocale", ru: "Сервис речи", ar: "خدمة الصوت", hi: "वॉइस सेवा", id: "Layanan Suara", vi: "Dịch vụ giọng nói", th: "บริการเสียง")
        case .textAI:
            return pick(language, zh: "AI 整理", en: "AI Refinement", ja: "AI 整理", ko: "AI 정리", fr: "Retouche IA", de: "KI-Überarbeitung", es: "Mejora con IA", pt: "Refinamento por IA", it: "Rifinitura IA", ru: "Обработка ИИ", ar: "تحسين بالذكاء الاصطناعي", hi: "AI सुधार", id: "Perapian AI", vi: "Chỉnh sửa AI", th: "ปรับข้อความด้วย AI")
        case .textAISubtitle:
            return pick(language, zh: "负责润色、翻译、整理和对选中文字提问。", en: "Handles polishing, translation, cleanup, and selected-text questions.", ja: "推敲、翻訳、整理、選択テキストへの質問を処理します。", ko: "다듬기, 번역, 정리, 선택 텍스트 질문을 처리합니다.", fr: "Gère la retouche, la traduction et les questions sur texte sélectionné.", de: "Übernimmt Überarbeitung, Übersetzung und Fragen zu markiertem Text.", es: "Gestiona pulido, traducción y preguntas sobre texto seleccionado.", pt: "Cuida de polimento, tradução e perguntas sobre texto selecionado.", it: "Gestisce rifinitura, traduzione e domande sul testo selezionato.", ru: "Отвечает за улучшение, перевод и вопросы по выделенному тексту.", ar: "يعالج التحسين والترجمة والأسئلة عن النص المحدد.", hi: "सुधार, अनुवाद और चुने हुए टेक्स्ट के प्रश्न संभालता है.", id: "Menangani perapian, terjemahan, dan pertanyaan teks terpilih.", vi: "Xử lý chỉnh sửa, dịch và câu hỏi về văn bản đã chọn.", th: "จัดการการปรับข้อความ แปล และถามจากข้อความที่เลือก")
        case .aiService:
            return pick(language, zh: "AI 服务", en: "AI Service", ja: "AI サービス", ko: "AI 서비스", fr: "Service IA", de: "KI-Dienst", es: "Servicio de IA", pt: "Serviço de IA", it: "Servizio IA", ru: "Сервис ИИ", ar: "خدمة الذكاء الاصطناعي", hi: "AI सेवा", id: "Layanan AI", vi: "Dịch vụ AI", th: "บริการ AI")
        case .advancedSettings:
            return pick(language, zh: "高级配置", en: "Advanced Settings", ja: "詳細設定", ko: "고급 설정", fr: "Réglages avancés", de: "Erweiterte Einstellungen", es: "Ajustes avanzados", pt: "Configurações avançadas", it: "Impostazioni avanzate", ru: "Расширенные настройки", ar: "إعدادات متقدمة", hi: "उन्नत सेटिंग्स", id: "Pengaturan Lanjutan", vi: "Cài đặt nâng cao", th: "การตั้งค่าขั้นสูง")
        case .appearanceAndPermissions:
            return pick(language, zh: "外观与权限", en: "Appearance & Permissions", ja: "外観と権限", ko: "모양 및 권한", fr: "Apparence et autorisations", de: "Darstellung & Berechtigungen", es: "Apariencia y permisos", pt: "Aparência e permissões", it: "Aspetto e permessi", ru: "Внешний вид и разрешения", ar: "المظهر والأذونات", hi: "दिखावट और अनुमतियाँ", id: "Tampilan & Izin", vi: "Giao diện & quyền", th: "หน้าตาและสิทธิ์")
        case .appearanceAndPermissionsSubtitle:
            return pick(language, zh: "控制界面语言、历史记录和系统权限。", en: "Control interface language, history, and system permissions.", ja: "表示言語、履歴、システム権限を管理します。", ko: "인터페이스 언어, 기록, 시스템 권한을 관리합니다.", fr: "Contrôlez la langue, l'historique et les autorisations.", de: "Steuern Sie Sprache, Verlauf und Systemberechtigungen.", es: "Controla idioma, historial y permisos.", pt: "Controle idioma, histórico e permissões.", it: "Controlla lingua, cronologia e permessi.", ru: "Управляйте языком, историей и разрешениями.", ar: "تحكم في اللغة والسجل والأذونات.", hi: "भाषा, इतिहास और अनुमतियाँ नियंत्रित करें.", id: "Atur bahasa, riwayat, dan izin.", vi: "Điều khiển ngôn ngữ, lịch sử và quyền.", th: "ควบคุมภาษา ประวัติ และสิทธิ์")
        case .tutorial:
            return pick(language, zh: "入门教程", en: "Getting Started", ja: "入門ガイド", ko: "시작하기", fr: "Premiers pas", de: "Erste Schritte", es: "Primeros pasos", pt: "Primeiros passos", it: "Guida iniziale", ru: "Начало работы", ar: "البدء", hi: "शुरुआत", id: "Mulai", vi: "Bắt đầu", th: "เริ่มต้นใช้งาน")
        case .tutorialSubtitle:
            return pick(language, zh: "重新查看首次打开时的新手引导。", en: "Open the first-run walkthrough again.", ja: "初回起動時のガイドをもう一度開きます。", ko: "처음 실행 안내를 다시 엽니다.", fr: "Rouvrez le guide de première utilisation.", de: "Öffnet die Einführung vom ersten Start erneut.", es: "Vuelve a abrir la guía inicial.", pt: "Abra novamente o guia inicial.", it: "Riapri la guida del primo avvio.", ru: "Снова открыть первый тур.", ar: "افتح دليل الاستخدام الأول مرة أخرى.", hi: "पहली बार वाला मार्गदर्शन फिर खोलें.", id: "Buka lagi panduan awal.", vi: "Mở lại hướng dẫn lần đầu.", th: "เปิดคำแนะนำครั้งแรกอีกครั้ง")
        case .reopenTutorial:
            return pick(language, zh: "重新打开入门教程", en: "Reopen Tutorial", ja: "ガイドを再度開く", ko: "튜토리얼 다시 열기", fr: "Rouvrir le tutoriel", de: "Tutorial erneut öffnen", es: "Reabrir tutorial", pt: "Reabrir tutorial", it: "Riapri tutorial", ru: "Открыть обучение снова", ar: "إعادة فتح الدليل", hi: "ट्यूटोरियल फिर खोलें", id: "Buka Ulang Tutorial", vi: "Mở lại hướng dẫn", th: "เปิดบทแนะนำอีกครั้ง")
        case .saveHistory:
            return pick(language, zh: "保存历史记录", en: "Save History", ja: "履歴を保存", ko: "기록 저장", fr: "Enregistrer l'historique", de: "Verlauf speichern", es: "Guardar historial", pt: "Salvar histórico", it: "Salva cronologia", ru: "Сохранять историю", ar: "حفظ السجل", hi: "इतिहास सहेजें", id: "Simpan Riwayat", vi: "Lưu lịch sử", th: "บันทึกประวัติ")
        case .launchAtLogin:
            return pick(language, zh: "开机自动启动", en: "Launch at Login", ja: "ログイン時に起動", ko: "로그인 시 실행", fr: "Lancer à l'ouverture", de: "Bei Anmeldung starten", es: "Abrir al iniciar sesión", pt: "Abrir ao entrar", it: "Avvia al login", ru: "Запуск при входе", ar: "تشغيل عند الدخول", hi: "लॉगिन पर शुरू करें", id: "Jalankan saat Login", vi: "Mở khi đăng nhập", th: "เปิดเมื่อเข้าสู่ระบบ")
        case .comingAfterPackaging:
            return pick(language, zh: "打包完善后开放", en: "Available after packaging is finalized", ja: "パッケージ完了後に利用可能", ko: "패키징 완료 후 제공", fr: "Disponible après finalisation du paquet", de: "Nach finaler Paketierung verfügbar", es: "Disponible tras finalizar el paquete", pt: "Disponível após finalizar o pacote", it: "Disponibile dopo il pacchetto finale", ru: "Доступно после финальной сборки", ar: "متاح بعد اكتمال الحزمة", hi: "पैकेजिंग पूरी होने के बाद उपलब्ध", id: "Tersedia setelah paket selesai", vi: "Có sau khi hoàn tất đóng gói", th: "ใช้ได้หลังแพ็กเกจเสร็จ")
        case .apiSetup:
            return pick(language, zh: "API 配置", en: "API Setup", ja: "API 設定", ko: "API 설정", fr: "Configuration API", de: "API-Einrichtung", es: "Configuración API", pt: "Configuração da API", it: "Configurazione API", ru: "Настройка API", ar: "إعداد API", hi: "API सेटअप", id: "Pengaturan API", vi: "Thiết lập API", th: "ตั้งค่า API")
        case .apiSetupDescription:
            return pick(language, zh: "第一次使用需要配置语音识别和文字整理的 API。推荐语音和文字整理都先用阿里云百炼；以后可以从菜单栏图标随时更换。", en: "First use requires speech and text AI API setup. You can change providers later from the menu bar.", ja: "初回利用には音声認識とテキスト AI の API 設定が必要です。後でメニューバーから変更できます。", ko: "처음 사용하려면 음성 및 텍스트 AI API 설정이 필요합니다. 나중에 메뉴 막대에서 변경할 수 있습니다.", fr: "La première utilisation nécessite les API voix et texte. Vous pourrez les changer depuis la barre de menus.", de: "Für die erste Nutzung müssen Sprach- und Text-KI-APIs eingerichtet werden. Anbieter können später geändert werden.", es: "El primer uso requiere configurar API de voz y texto. Puedes cambiar proveedores luego.", pt: "O primeiro uso exige APIs de voz e texto. Você pode mudar provedores depois.", it: "Il primo uso richiede API voce e testo. Puoi cambiare provider in seguito.", ru: "Для первого запуска нужны API речи и текста. Провайдеров можно сменить позже.", ar: "يتطلب الاستخدام الأول إعداد API للصوت والنص. يمكنك تغيير المزود لاحقًا.", hi: "पहली बार उपयोग के लिए वॉइस और टेक्स्ट API चाहिए. बाद में प्रदाता बदल सकते हैं.", id: "Penggunaan pertama memerlukan API suara dan teks. Penyedia bisa diganti nanti.", vi: "Lần đầu cần thiết lập API giọng nói và văn bản. Có thể đổi nhà cung cấp sau.", th: "ครั้งแรกต้องตั้งค่า API เสียงและข้อความ เปลี่ยนผู้ให้บริการได้ภายหลัง")
        case .openAliyun:
            return pick(language, zh: "打开阿里云百炼", en: "Open Alibaba Bailian", ja: "Alibaba Bailian を開く", ko: "Alibaba Bailian 열기", fr: "Ouvrir Alibaba Bailian", de: "Alibaba Bailian öffnen", es: "Abrir Alibaba Bailian", pt: "Abrir Alibaba Bailian", it: "Apri Alibaba Bailian", ru: "Открыть Alibaba Bailian", ar: "فتح Alibaba Bailian", hi: "Alibaba Bailian खोलें", id: "Buka Alibaba Bailian", vi: "Mở Alibaba Bailian", th: "เปิด Alibaba Bailian")
        case .openSiliconFlow:
            return pick(language, zh: "打开硅基流动", en: "Open SiliconFlow", ja: "SiliconFlow を開く", ko: "SiliconFlow 열기", fr: "Ouvrir SiliconFlow", de: "SiliconFlow öffnen", es: "Abrir SiliconFlow", pt: "Abrir SiliconFlow", it: "Apri SiliconFlow", ru: "Открыть SiliconFlow", ar: "فتح SiliconFlow", hi: "SiliconFlow खोलें", id: "Buka SiliconFlow", vi: "Mở SiliconFlow", th: "เปิด SiliconFlow")
        case .modelLabel:
            return pick(language, zh: "模型", en: "Model", ja: "モデル", ko: "모델", fr: "Modèle", de: "Modell", es: "Modelo", pt: "Modelo", it: "Modello", ru: "Модель", ar: "النموذج", hi: "मॉडल", id: "Model", vi: "Mô hình", th: "โมเดล")
        case .endpoint:
            return pick(language, zh: "接口地址", en: "Endpoint", ja: "エンドポイント", ko: "엔드포인트", fr: "Point de terminaison", de: "Endpunkt", es: "Endpoint", pt: "Endpoint", it: "Endpoint", ru: "Endpoint", ar: "نقطة النهاية", hi: "Endpoint", id: "Endpoint", vi: "Endpoint", th: "Endpoint")
        case .close:
            return pick(language, zh: "关闭", en: "Close", ja: "閉じる", ko: "닫기", fr: "Fermer", de: "Schließen", es: "Cerrar", pt: "Fechar", it: "Chiudi", ru: "Закрыть", ar: "إغلاق", hi: "बंद करें", id: "Tutup", vi: "Đóng", th: "ปิด")
        case .cancel:
            return pick(language, zh: "取消", en: "Cancel", ja: "キャンセル", ko: "취소", fr: "Annuler", de: "Abbrechen", es: "Cancelar", pt: "Cancelar", it: "Annulla", ru: "Отмена", ar: "إلغاء", hi: "रद्द करें", id: "Batal", vi: "Hủy", th: "ยกเลิก")
        case .shortcutHint:
            return pick(language, zh: "1 自动  2 直写  3 翻译  4 润色", en: "1 Auto  2 Dictate  3 Translate  4 Polish", ja: "1 自動  2 入力  3 翻訳  4 整理", ko: "1 자동  2 받아쓰기  3 번역  4 다듬기", fr: "1 Auto  2 Dictée  3 Traduire  4 Retoucher", de: "1 Auto  2 Diktat  3 Übersetzen  4 Überarbeiten", es: "1 Auto  2 Dictar  3 Traducir  4 Pulir", pt: "1 Auto  2 Ditado  3 Traduzir  4 Polir", it: "1 Auto  2 Dettatura  3 Traduci  4 Rifinisci", ru: "1 Авто  2 Диктовка  3 Перевод  4 Улучшить", ar: "1 تلقائي  2 إملاء  3 ترجمة  4 تحسين", hi: "1 ऑटो  2 डिक्टेट  3 अनुवाद  4 सुधार", id: "1 Auto  2 Dikte  3 Terjemah  4 Poles", vi: "1 Tự động  2 Đọc  3 Dịch  4 Chỉnh", th: "1 อัตโนมัติ  2 พูด  3 แปล  4 ปรับ")
        case .readyMessage:
            return pick(language, zh: "准备好了", en: "Ready", ja: "準備完了", ko: "준비됨", fr: "Prêt", de: "Bereit", es: "Listo", pt: "Pronto", it: "Pronto", ru: "Готово", ar: "جاهز", hi: "तैयार", id: "Siap", vi: "Sẵn sàng", th: "พร้อม")
        case .listeningMessage:
            return pick(language, zh: "正在听你说话...", en: "Listening...", ja: "聞き取り中...", ko: "듣는 중...", fr: "Écoute...", de: "Hört zu...", es: "Escuchando...", pt: "Ouvindo...", it: "In ascolto...", ru: "Слушаю...", ar: "يستمع...", hi: "सुन रहा है...", id: "Mendengarkan...", vi: "Đang nghe...", th: "กำลังฟัง...")
        case .finalizingMessage:
            return pick(language, zh: "正在等待语音识别结果...", en: "Finishing speech recognition...", ja: "音声認識を完了しています...", ko: "음성 인식을 마무리하는 중...", fr: "Reconnaissance vocale en cours...", de: "Spracherkennung wird abgeschlossen...", es: "Finalizando reconocimiento...", pt: "Finalizando reconhecimento...", it: "Riconoscimento in corso...", ru: "Завершение распознавания...", ar: "ينهي التعرف على الكلام...", hi: "वॉइस पहचान पूरी हो रही है...", id: "Menyelesaikan pengenalan suara...", vi: "Đang hoàn tất nhận dạng...", th: "กำลังจบการรู้จำเสียง...")
        case .transformingMessage:
            return pick(language, zh: "正在整理文字...", en: "Refining text...", ja: "テキストを整理中...", ko: "텍스트 정리 중...", fr: "Traitement du texte...", de: "Text wird überarbeitet...", es: "Mejorando texto...", pt: "Refinando texto...", it: "Rifinitura testo...", ru: "Обработка текста...", ar: "يحسن النص...", hi: "टेक्स्ट सुधर रहा है...", id: "Merapikan teks...", vi: "Đang chỉnh sửa văn bản...", th: "กำลังปรับข้อความ...")
        case .insertingMessage:
            return pick(language, zh: "正在写入当前输入框...", en: "Inserting into the active field...", ja: "現在の入力欄に挿入中...", ko: "현재 입력칸에 입력 중...", fr: "Insertion dans le champ actif...", de: "Einfügen in aktives Feld...", es: "Insertando en el campo activo...", pt: "Inserindo no campo ativo...", it: "Inserimento nel campo attivo...", ru: "Вставка в активное поле...", ar: "يدرج في الحقل النشط...", hi: "सक्रिय फ़ील्ड में डाल रहा है...", id: "Memasukkan ke bidang aktif...", vi: "Đang chèn vào ô hiện tại...", th: "กำลังใส่ในช่องที่ใช้งาน...")
        case .noSpeechMessage:
            return pick(language, zh: "没有检测到输入，稍后自动关闭。", en: "No input detected. This will close shortly.", ja: "入力が検出されません。まもなく閉じます。", ko: "입력이 감지되지 않았습니다. 곧 닫힙니다.", fr: "Aucune entrée détectée. Fermeture imminente.", de: "Keine Eingabe erkannt. Wird gleich geschlossen.", es: "No se detectó entrada. Se cerrará pronto.", pt: "Nenhuma entrada detectada. Fechará em breve.", it: "Nessun input rilevato. Si chiuderà a breve.", ru: "Ввод не обнаружен. Скоро закроется.", ar: "لم يتم اكتشاف إدخال. سيُغلق قريبًا.", hi: "कोई इनपुट नहीं मिला। यह जल्द बंद होगा.", id: "Tidak ada input. Akan segera ditutup.", vi: "Không phát hiện đầu vào. Sẽ sớm đóng.", th: "ไม่พบอินพุต จะปิดเร็ว ๆ นี้")
        case .failedMessage:
            return pick(language, zh: "这次听写没有完成。", en: "This dictation did not finish.", ja: "今回の音声入力は完了しませんでした。", ko: "이번 받아쓰기가 완료되지 않았습니다.", fr: "Cette dictée n'est pas terminée.", de: "Dieses Diktat wurde nicht abgeschlossen.", es: "Este dictado no se completó.", pt: "Este ditado não foi concluído.", it: "Questa dettatura non è stata completata.", ru: "Эта диктовка не завершена.", ar: "لم يكتمل هذا الإملاء.", hi: "यह डिक्टेशन पूरा नहीं हुआ.", id: "Dikte ini belum selesai.", vi: "Lần đọc này chưa hoàn tất.", th: "การพิมพ์ตามเสียงครั้งนี้ไม่เสร็จ")
        case .openAccessibilitySettings:
            return pick(language, zh: "打开辅助功能设置", en: "Open Accessibility Settings", ja: "アクセシビリティ設定を開く", ko: "손쉬운 사용 설정 열기", fr: "Ouvrir Accessibilité", de: "Bedienungshilfen öffnen", es: "Abrir accesibilidad", pt: "Abrir acessibilidade", it: "Apri Accessibilità", ru: "Открыть доступность", ar: "فتح إعدادات إمكانية الوصول", hi: "Accessibility सेटिंग्स खोलें", id: "Buka Aksesibilitas", vi: "Mở Trợ năng", th: "เปิดการช่วยการเข้าถึง")
        case .openModelSettings:
            return pick(language, zh: "打开模型设置", en: "Open Model Settings", ja: "モデル設定を開く", ko: "모델 설정 열기", fr: "Ouvrir les réglages du modèle", de: "Modelleinstellungen öffnen", es: "Abrir ajustes del modelo", pt: "Abrir configurações do modelo", it: "Apri impostazioni modello", ru: "Открыть настройки модели", ar: "فتح إعدادات النموذج", hi: "मॉडल सेटिंग्स खोलें", id: "Buka Pengaturan Model", vi: "Mở cài đặt mô hình", th: "เปิดการตั้งค่าโมเดล")
        case .speechAPIKeyPlaceholder:
            return pick(language, zh: "语音 API Key", en: "Speech API Key", ja: "音声 API Key", ko: "음성 API Key", fr: "Clé API voix", de: "Sprach-API-Key", es: "API Key de voz", pt: "API Key de voz", it: "API Key voce", ru: "API-ключ речи", ar: "مفتاح API للصوت", hi: "वॉइस API Key", id: "API Key suara", vi: "API Key giọng nói", th: "คีย์ API เสียง")
        case .speechModelPlaceholder:
            return pick(language, zh: "语音模型", en: "Speech Model", ja: "音声モデル", ko: "음성 모델", fr: "Modèle vocal", de: "Sprachmodell", es: "Modelo de voz", pt: "Modelo de voz", it: "Modello vocale", ru: "Модель речи", ar: "نموذج الصوت", hi: "वॉइस मॉडल", id: "Model suara", vi: "Mô hình giọng nói", th: "โมเดลเสียง")
        case .speechEndpointPlaceholder:
            return pick(language, zh: "语音接口地址", en: "Speech Endpoint", ja: "音声エンドポイント", ko: "음성 엔드포인트", fr: "Endpoint vocal", de: "Sprach-Endpunkt", es: "Endpoint de voz", pt: "Endpoint de voz", it: "Endpoint voce", ru: "Endpoint речи", ar: "نقطة نهاية الصوت", hi: "वॉइस endpoint", id: "Endpoint suara", vi: "Endpoint giọng nói", th: "Endpoint เสียง")
        case .textAPIKeyPlaceholder:
            return pick(language, zh: "AI API Key", en: "AI API Key", ja: "AI API Key", ko: "AI API Key", fr: "Clé API IA", de: "KI-API-Key", es: "API Key de IA", pt: "API Key de IA", it: "API Key IA", ru: "API-ключ ИИ", ar: "مفتاح API للذكاء الاصطناعي", hi: "AI API Key", id: "API Key AI", vi: "API Key AI", th: "คีย์ API AI")
        case .textModelPlaceholder:
            return pick(language, zh: "AI 模型", en: "AI Model", ja: "AI モデル", ko: "AI 모델", fr: "Modèle IA", de: "KI-Modell", es: "Modelo de IA", pt: "Modelo de IA", it: "Modello IA", ru: "Модель ИИ", ar: "نموذج الذكاء الاصطناعي", hi: "AI मॉडल", id: "Model AI", vi: "Mô hình AI", th: "โมเดล AI")
        case .textEndpointPlaceholder:
            return pick(language, zh: "AI 接口地址", en: "AI Endpoint", ja: "AI エンドポイント", ko: "AI 엔드포인트", fr: "Endpoint IA", de: "KI-Endpunkt", es: "Endpoint de IA", pt: "Endpoint de IA", it: "Endpoint IA", ru: "Endpoint ИИ", ar: "نقطة نهاية الذكاء الاصطناعي", hi: "AI endpoint", id: "Endpoint AI", vi: "Endpoint AI", th: "Endpoint AI")
        case .permissions:
            return pick(language, zh: "权限", en: "Permissions", ja: "権限", ko: "권한", fr: "Autorisations", de: "Berechtigungen", es: "Permisos", pt: "Permissões", it: "Permessi", ru: "Разрешения", ar: "الأذونات", hi: "अनुमतियाँ", id: "Izin", vi: "Quyền", th: "สิทธิ์")
        case .microphone:
            return pick(language, zh: "麦克风", en: "Microphone", ja: "マイク", ko: "마이크", fr: "Microphone", de: "Mikrofon", es: "Micrófono", pt: "Microfone", it: "Microfono", ru: "Микрофон", ar: "الميكروفون", hi: "माइक्रोफ़ोन", id: "Mikrofon", vi: "Micrô", th: "ไมโครโฟน")
        case .accessibility:
            return pick(language, zh: "辅助功能", en: "Accessibility", ja: "アクセシビリティ", ko: "손쉬운 사용", fr: "Accessibilité", de: "Bedienungshilfen", es: "Accesibilidad", pt: "Acessibilidade", it: "Accessibilità", ru: "Универсальный доступ", ar: "إمكانية الوصول", hi: "Accessibility", id: "Aksesibilitas", vi: "Trợ năng", th: "การช่วยการเข้าถึง")
        case .openMicrophonePermission:
            return pick(language, zh: "打开麦克风权限", en: "Open Microphone Permission", ja: "マイク権限を開く", ko: "마이크 권한 열기", fr: "Ouvrir l'autorisation micro", de: "Mikrofonberechtigung öffnen", es: "Abrir permiso de micrófono", pt: "Abrir permissão do microfone", it: "Apri permesso microfono", ru: "Открыть доступ к микрофону", ar: "فتح إذن الميكروفون", hi: "माइक्रोफ़ोन अनुमति खोलें", id: "Buka izin mikrofon", vi: "Mở quyền micrô", th: "เปิดสิทธิ์ไมโครโฟน")
        case .openAccessibilityPermission:
            return pick(language, zh: "打开辅助功能权限", en: "Open Accessibility Permission", ja: "アクセシビリティ権限を開く", ko: "손쉬운 사용 권한 열기", fr: "Ouvrir l'autorisation d'accessibilité", de: "Bedienungshilfen-Berechtigung öffnen", es: "Abrir permiso de accesibilidad", pt: "Abrir permissão de acessibilidade", it: "Apri permesso Accessibilità", ru: "Открыть доступность", ar: "فتح إذن إمكانية الوصول", hi: "Accessibility अनुमति खोलें", id: "Buka izin aksesibilitas", vi: "Mở quyền trợ năng", th: "เปิดสิทธิ์การช่วยการเข้าถึง")
        case .permissionAllowed:
            return pick(language, zh: "已允许", en: "Allowed", ja: "許可済み", ko: "허용됨", fr: "Autorisé", de: "Erlaubt", es: "Permitido", pt: "Permitido", it: "Consentito", ru: "Разрешено", ar: "مسموح", hi: "अनुमत", id: "Diizinkan", vi: "Đã cho phép", th: "อนุญาตแล้ว")
        case .permissionDenied:
            return pick(language, zh: "未允许", en: "Not Allowed", ja: "未許可", ko: "허용 안 됨", fr: "Non autorisé", de: "Nicht erlaubt", es: "No permitido", pt: "Não permitido", it: "Non consentito", ru: "Не разрешено", ar: "غير مسموح", hi: "अनुमत नहीं", id: "Tidak diizinkan", vi: "Chưa cho phép", th: "ยังไม่อนุญาต")
        case .permissionNotAsked:
            return pick(language, zh: "未询问", en: "Not Asked", ja: "未確認", ko: "아직 묻지 않음", fr: "Non demandé", de: "Noch nicht gefragt", es: "Sin preguntar", pt: "Não solicitado", it: "Non richiesto", ru: "Не запрошено", ar: "لم يُطلب بعد", hi: "नहीं पूछा गया", id: "Belum diminta", vi: "Chưa hỏi", th: "ยังไม่ได้ถาม")
        case .permissionUnknown:
            return pick(language, zh: "未知", en: "Unknown", ja: "不明", ko: "알 수 없음", fr: "Inconnu", de: "Unbekannt", es: "Desconocido", pt: "Desconhecido", it: "Sconosciuto", ru: "Неизвестно", ar: "غير معروف", hi: "अज्ञात", id: "Tidak diketahui", vi: "Không rõ", th: "ไม่ทราบ")
        case .unableToSaveSpeechAPIKey:
            return pick(language, zh: "无法保存语音 API Key", en: "Could not save Speech API Key", ja: "音声 API Key を保存できません", ko: "음성 API Key를 저장할 수 없습니다", fr: "Impossible d'enregistrer la clé API voix", de: "Sprach-API-Key konnte nicht gespeichert werden", es: "No se pudo guardar la API Key de voz", pt: "Não foi possível salvar a API Key de voz", it: "Impossibile salvare la API Key voce", ru: "Не удалось сохранить API-ключ речи", ar: "تعذر حفظ مفتاح API للصوت", hi: "वॉइस API Key सहेज नहीं सके", id: "Tidak dapat menyimpan API Key suara", vi: "Không thể lưu API Key giọng nói", th: "บันทึกคีย์ API เสียงไม่ได้")
        case .unableToSaveTextAPIKey:
            return pick(language, zh: "无法保存文字 AI API Key", en: "Could not save AI API Key", ja: "AI API Key を保存できません", ko: "AI API Key를 저장할 수 없습니다", fr: "Impossible d'enregistrer la clé API IA", de: "KI-API-Key konnte nicht gespeichert werden", es: "No se pudo guardar la API Key de IA", pt: "Não foi possível salvar a API Key de IA", it: "Impossibile salvare la API Key IA", ru: "Не удалось сохранить API-ключ ИИ", ar: "تعذر حفظ مفتاح API للذكاء الاصطناعي", hi: "AI API Key सहेज नहीं सके", id: "Tidak dapat menyimpan API Key AI", vi: "Không thể lưu API Key AI", th: "บันทึกคีย์ API AI ไม่ได้")
        }
    }

    static func modeSubtitle(_ mode: SpeakMoreMode, language: AppLanguage) -> String {
        switch mode {
        case .auto:
            return pick(language, zh: "自动判断是直接输入、整理、分点、润色还是翻译", en: "Automatically choose dictation, cleanup, bullets, polish, or translation.", ja: "入力、整理、箇条書き、推敲、翻訳を自動判断します。", ko: "받아쓰기, 정리, 목록화, 다듬기, 번역을 자동으로 판단합니다.", fr: "Choisit automatiquement dictée, nettoyage, listes, retouche ou traduction.", de: "Wählt automatisch Diktat, Aufräumen, Listen, Überarbeitung oder Übersetzung.", es: "Elige automáticamente dictado, limpieza, viñetas, pulido o traducción.", pt: "Escolhe automaticamente ditado, limpeza, tópicos, polimento ou tradução.", it: "Sceglie automaticamente dettatura, pulizia, punti, rifinitura o traduzione.", ru: "Автоматически выбирает диктовку, очистку, списки, улучшение или перевод.", ar: "يختار تلقائياً الإملاء أو التنظيف أو النقاط أو التحسين أو الترجمة.", hi: "डिक्टेशन, सफाई, बिंदु, सुधार या अनुवाद अपने-आप चुनता है.", id: "Otomatis memilih dikte, rapi, poin, poles, atau terjemah.", vi: "Tự chọn đọc, dọn văn bản, gạch đầu dòng, chỉnh sửa hoặc dịch.", th: "เลือกพูดตามเสียง จัดข้อความ หัวข้อย่อย ปรับ หรือแปลอัตโนมัติ")
        case .dictate:
            return pick(language, zh: "轻度清理口语，尽量保留原话", en: "Lightly clean speech while keeping your original wording.", ja: "話し言葉を軽く整え、原文をできるだけ保ちます。", ko: "말투를 가볍게 정리하고 원문을 최대한 유지합니다.", fr: "Nettoie légèrement la parole en gardant vos mots.", de: "Bereinigt gesprochene Sprache leicht und behält Ihre Worte bei.", es: "Limpia ligeramente la voz y conserva tus palabras.", pt: "Limpa levemente a fala mantendo suas palavras.", it: "Pulisce leggermente il parlato mantenendo le parole originali.", ru: "Слегка очищает речь, сохраняя ваши формулировки.", ar: "ينظف الكلام قليلاً مع الحفاظ على صياغتك.", hi: "मूल शब्द रखते हुए बोलचाल को हल्का साफ करता है.", id: "Membersihkan ucapan ringan sambil mempertahankan kata asli.", vi: "Dọn nhẹ lời nói và giữ cách diễn đạt gốc.", th: "เกลาคำพูดเล็กน้อยโดยคงถ้อยคำเดิม")
        case .translate:
            return pick(language, zh: "把语音翻译成目标语言", en: "Translate your speech into the target language.", ja: "音声を指定した言語に翻訳します。", ko: "음성을 대상 언어로 번역합니다.", fr: "Traduit votre voix dans la langue cible.", de: "Übersetzt Sprache in die Zielsprache.", es: "Traduce tu voz al idioma destino.", pt: "Traduz sua fala para o idioma de destino.", it: "Traduce la voce nella lingua di destinazione.", ru: "Переводит речь на целевой язык.", ar: "يترجم كلامك إلى اللغة الهدف.", hi: "आपकी आवाज़ को लक्ष्य भाषा में अनुवाद करता है.", id: "Menerjemahkan suara ke bahasa target.", vi: "Dịch lời nói sang ngôn ngữ đích.", th: "แปลเสียงเป็นภาษาเป้าหมาย")
        case .polish:
            return pick(language, zh: "把粗糙口语改成可直接发送的文字", en: "Turn rough speech into text ready to send.", ja: "粗い話し言葉をそのまま送れる文章にします。", ko: "거친 말을 바로 보낼 수 있는 글로 바꿉니다.", fr: "Transforme une parole brute en texte prêt à envoyer.", de: "Macht rohe Sprache zu sendefertigem Text.", es: "Convierte voz cruda en texto listo para enviar.", pt: "Transforma fala bruta em texto pronto para enviar.", it: "Trasforma parlato grezzo in testo pronto da inviare.", ru: "Преобразует черновую речь в готовый текст.", ar: "يحول الكلام الخام إلى نص جاهز للإرسال.", hi: "कच्ची बात को भेजने योग्य टेक्स्ट बनाता है.", id: "Mengubah ucapan kasar menjadi teks siap kirim.", vi: "Biến lời nói thô thành văn bản sẵn sàng gửi.", th: "เปลี่ยนคำพูดหยาบเป็นข้อความพร้อมส่ง")
        case .askSelectedText:
            return pick(language, zh: "对当前选中的文字执行语音指令", en: "Run a spoken instruction on the selected text.", ja: "選択中のテキストに音声指示を実行します。", ko: "선택한 텍스트에 음성 지시를 실행합니다.", fr: "Applique une instruction vocale au texte sélectionné.", de: "Wendet eine gesprochene Anweisung auf markierten Text an.", es: "Ejecuta una instrucción hablada sobre el texto seleccionado.", pt: "Executa uma instrução falada no texto selecionado.", it: "Esegue un comando vocale sul testo selezionato.", ru: "Выполняет голосовую команду над выделенным текстом.", ar: "ينفذ أمراً صوتياً على النص المحدد.", hi: "चुने हुए टेक्स्ट पर बोले गए निर्देश चलाता है.", id: "Menjalankan instruksi suara pada teks terpilih.", vi: "Chạy lệnh nói trên văn bản đã chọn.", th: "ใช้คำสั่งเสียงกับข้อความที่เลือก")
        }
    }

    static func polishIntensityTitle(_ intensity: TextPolishIntensity, language: AppLanguage) -> String {
        switch intensity {
        case .light:
            return pick(language, zh: "弱", en: "Light", ja: "弱", ko: "약함", fr: "Léger", de: "Leicht", es: "Ligero", pt: "Leve", it: "Leggero", ru: "Легкая", ar: "خفيف", hi: "हल्का", id: "Ringan", vi: "Nhẹ", th: "เบา")
        case .medium:
            return pick(language, zh: "中", en: "Medium", ja: "中", ko: "중간", fr: "Moyen", de: "Mittel", es: "Medio", pt: "Médio", it: "Medio", ru: "Средняя", ar: "متوسط", hi: "मध्यम", id: "Sedang", vi: "Vừa", th: "กลาง")
        case .strong:
            return pick(language, zh: "强", en: "Strong", ja: "強", ko: "강함", fr: "Fort", de: "Stark", es: "Fuerte", pt: "Forte", it: "Forte", ru: "Сильная", ar: "قوي", hi: "मजबूत", id: "Kuat", vi: "Mạnh", th: "แรง")
        }
    }

    static func voiceInputShortcutTriggerTitle(_ trigger: VoiceInputShortcutTrigger, language: AppLanguage) -> String {
        switch trigger {
        case .pressAndHold:
            return pick(language, zh: "按住说话", en: "Hold to Speak", ja: "押して話す", ko: "누르고 말하기", fr: "Maintenir pour parler", de: "Zum Sprechen halten", es: "Mantener para hablar", pt: "Segurar para falar", it: "Tieni per parlare", ru: "Удерживать для речи", ar: "اضغط للتحدث", hi: "बोलने के लिए दबाए रखें", id: "Tahan untuk bicara", vi: "Giữ để nói", th: "กดค้างเพื่อพูด")
        case .toggle:
            return pick(language, zh: "按一下开始 / 再按一下结束", en: "Tap to Start / Tap to Stop", ja: "押して開始 / もう一度で終了", ko: "눌러 시작 / 다시 눌러 종료", fr: "Appuyer pour démarrer / arrêter", de: "Drücken zum Starten / Stoppen", es: "Pulsar para iniciar / detener", pt: "Tocar para iniciar / parar", it: "Premi per iniziare / fermare", ru: "Нажать для старта / стопа", ar: "اضغط للبدء / اضغط للإيقاف", hi: "शुरू/रोकने के लिए दबाएँ", id: "Tekan untuk mulai / berhenti", vi: "Bấm để bắt đầu / dừng", th: "กดเพื่อเริ่ม / กดอีกครั้งเพื่อหยุด")
        }
    }

    static func polishIntensitySubtitle(_ intensity: TextPolishIntensity, language: AppLanguage) -> String {
        switch intensity {
        case .light:
            return pick(language, zh: "只做纠错和标点，尽量保留原话", en: "Only fix errors and punctuation; keep wording close.", ja: "誤字と句読点だけを整え、原文を保ちます。", ko: "오류와 문장부호만 고치고 원문을 유지합니다.", fr: "Corrige seulement erreurs et ponctuation.", de: "Korrigiert nur Fehler und Zeichensetzung.", es: "Solo corrige errores y puntuación.", pt: "Só corrige erros e pontuação.", it: "Corregge solo errori e punteggiatura.", ru: "Исправляет только ошибки и пунктуацию.", ar: "يصحح الأخطاء والترقيم فقط.", hi: "सिर्फ गलतियाँ और विराम चिह्न ठीक करता है.", id: "Hanya memperbaiki kesalahan dan tanda baca.", vi: "Chỉ sửa lỗi và dấu câu.", th: "แก้เฉพาะข้อผิดพลาดและวรรคตอน")
        case .medium:
            return pick(language, zh: "默认推荐，适度断句和整理", en: "Recommended default; moderate cleanup and sentence breaks.", ja: "推奨設定。ほどよく区切り、整理します。", ko: "추천 기본값. 적당히 문장을 나누고 정리합니다.", fr: "Réglage recommandé, nettoyage modéré.", de: "Empfohlen; moderate Bereinigung und Satztrennung.", es: "Recomendado; limpieza y cortes moderados.", pt: "Recomendado; limpeza e frases moderadas.", it: "Consigliato; pulizia e frasi moderate.", ru: "Рекомендуется; умеренная очистка и деление.", ar: "الافتراضي الموصى به مع تحسين متوسط.", hi: "अनुशंसित; मध्यम सफाई और वाक्य विभाजन.", id: "Disarankan; perapian dan jeda kalimat sedang.", vi: "Mặc định khuyên dùng; chỉnh vừa phải.", th: "แนะนำเป็นค่าเริ่มต้น จัดข้อความพอดี")
        case .strong:
            return pick(language, zh: "更主动地分段、提炼和结构化", en: "More active paragraphing, summarizing, and structuring.", ja: "より積極的に段落化、要約、構造化します。", ko: "더 적극적으로 단락화, 요약, 구조화합니다.", fr: "Structure, résume et paragraphe davantage.", de: "Aktivere Absätze, Zusammenfassung und Struktur.", es: "Más párrafos, síntesis y estructura.", pt: "Mais parágrafos, síntese e estrutura.", it: "Più paragrafi, sintesi e struttura.", ru: "Активнее делит, обобщает и структурирует.", ar: "يفقر ويختصر وينظم النص بوضوح أكبر.", hi: "अधिक पैराग्राफ, सार और संरचना.", id: "Lebih aktif membuat paragraf, ringkasan, dan struktur.", vi: "Chủ động chia đoạn, tóm tắt và cấu trúc hơn.", th: "แบ่งย่อหน้า สรุป และจัดโครงสร้างมากขึ้น")
        }
    }

    static func speechRecognitionProviderTitle(_ provider: SpeechRecognitionProviderKind, language: AppLanguage) -> String {
        switch provider {
        case .aliyunBailianRealtime:
            return pick(language, zh: "阿里云百炼实时", en: "Alibaba Bailian Realtime", ja: "Alibaba Bailian リアルタイム", ko: "Alibaba Bailian 실시간", fr: "Alibaba Bailian temps réel", de: "Alibaba Bailian Echtzeit", es: "Alibaba Bailian en tiempo real", pt: "Alibaba Bailian em tempo real", it: "Alibaba Bailian in tempo reale", ru: "Alibaba Bailian в реальном времени", ar: "Alibaba Bailian الفوري", hi: "Alibaba Bailian रीयल टाइम", id: "Alibaba Bailian Realtime", vi: "Alibaba Bailian thời gian thực", th: "Alibaba Bailian เรียลไทม์")
        case .openAIRealtime:
            return pick(language, zh: "OpenAI 实时", en: "OpenAI Realtime", ja: "OpenAI リアルタイム", ko: "OpenAI 실시간", fr: "OpenAI temps réel", de: "OpenAI Echtzeit", es: "OpenAI en tiempo real", pt: "OpenAI em tempo real", it: "OpenAI in tempo reale", ru: "OpenAI в реальном времени", ar: "OpenAI الفوري", hi: "OpenAI रीयल टाइम", id: "OpenAI Realtime", vi: "OpenAI thời gian thực", th: "OpenAI เรียลไทม์")
        case .customOpenAIRealtime:
            return pick(language, zh: "自定义实时", en: "Custom Realtime", ja: "カスタム リアルタイム", ko: "사용자 지정 실시간", fr: "Temps réel personnalisé", de: "Eigene Echtzeit", es: "Realtime personalizado", pt: "Realtime personalizado", it: "Realtime personalizzato", ru: "Пользовательский realtime", ar: "Realtime مخصص", hi: "कस्टम Realtime", id: "Realtime kustom", vi: "Realtime tùy chỉnh", th: "Realtime กำหนดเอง")
        }
    }

    static func textAIProviderTitle(_ provider: TextAIProviderKind, language: AppLanguage) -> String {
        switch provider {
        case .siliconFlow:
            return pick(language, zh: "硅基流动", en: "SiliconFlow", ja: "SiliconFlow", ko: "SiliconFlow", fr: "SiliconFlow", de: "SiliconFlow", es: "SiliconFlow", pt: "SiliconFlow", it: "SiliconFlow", ru: "SiliconFlow", ar: "SiliconFlow", hi: "SiliconFlow", id: "SiliconFlow", vi: "SiliconFlow", th: "SiliconFlow")
        case .aliyunBailian:
            return pick(language, zh: "阿里云百炼", en: "Alibaba Bailian", ja: "Alibaba Bailian", ko: "Alibaba Bailian", fr: "Alibaba Bailian", de: "Alibaba Bailian", es: "Alibaba Bailian", pt: "Alibaba Bailian", it: "Alibaba Bailian", ru: "Alibaba Bailian", ar: "Alibaba Bailian", hi: "Alibaba Bailian", id: "Alibaba Bailian", vi: "Alibaba Bailian", th: "Alibaba Bailian")
        case .openAI:
            return "OpenAI"
        case .deepSeek:
            return "DeepSeek"
        case .custom:
            return pick(language, zh: "自定义", en: "Custom", ja: "カスタム", ko: "사용자 지정", fr: "Personnalisé", de: "Benutzerdefiniert", es: "Personalizado", pt: "Personalizado", it: "Personalizzato", ru: "Пользовательский", ar: "مخصص", hi: "कस्टम", id: "Kustom", vi: "Tùy chỉnh", th: "กำหนดเอง")
        }
    }

    static func audioQualityHint(_ issue: AudioQualityIssue, language: AppLanguage) -> String {
        switch issue {
        case .tooQuiet:
            return pick(language, zh: "声音偏小，靠近麦克风", en: "Voice is quiet; move closer to the microphone.", ja: "声が小さめです。マイクに近づいてください。", ko: "목소리가 작습니다. 마이크에 더 가까이 말해 주세요.", fr: "Voix faible ; rapprochez-vous du micro.", de: "Stimme ist leise; näher ans Mikrofon.", es: "Voz baja; acércate al micrófono.", pt: "Voz baixa; aproxime-se do microfone.", it: "Voce bassa; avvicinati al microfono.", ru: "Голос тихий; подойдите ближе к микрофону.", ar: "الصوت منخفض؛ اقترب من الميكروفون.", hi: "आवाज़ धीमी है; माइक्रोफ़ोन के करीब आएँ.", id: "Suara terlalu pelan; dekatkan ke mikrofon.", vi: "Giọng hơi nhỏ; hãy lại gần micrô.", th: "เสียงเบาเกินไป ขยับเข้าใกล้ไมโครโฟน")
        case .backgroundNoise:
            return pick(language, zh: "背景噪声较高，换个安静位置会更准", en: "Background noise is high; a quieter spot will improve accuracy.", ja: "背景ノイズが高めです。静かな場所だと精度が上がります。", ko: "배경 소음이 큽니다. 조용한 곳이면 정확도가 좋아집니다.", fr: "Bruit de fond élevé ; un lieu plus calme aidera.", de: "Viele Hintergrundgeräusche; ein ruhigerer Ort hilft.", es: "Hay mucho ruido; un lugar más tranquilo ayudará.", pt: "Há muito ruído; um local mais silencioso ajuda.", it: "Rumore di fondo alto; un luogo più silenzioso aiuta.", ru: "Много фонового шума; тише место улучшит точность.", ar: "الضوضاء عالية؛ مكان أهدأ يحسن الدقة.", hi: "पृष्ठभूमि शोर अधिक है; शांत जगह बेहतर होगी.", id: "Kebisingan tinggi; tempat lebih tenang akan membantu.", vi: "Nhiễu nền cao; nơi yên tĩnh hơn sẽ chính xác hơn.", th: "เสียงรบกวนสูง ที่เงียบกว่าจะช่วยให้แม่นขึ้น")
        case .clipping:
            return pick(language, zh: "麦克风音量过大，稍微离远一点", en: "Microphone input is too loud; move back slightly.", ja: "マイク入力が大きすぎます。少し離れてください。", ko: "마이크 입력이 너무 큽니다. 조금 떨어져 말해 주세요.", fr: "Entrée micro trop forte ; reculez légèrement.", de: "Mikrofoneingang ist zu laut; etwas Abstand nehmen.", es: "El micrófono está muy alto; aléjate un poco.", pt: "O microfone está alto demais; afaste-se um pouco.", it: "Microfono troppo alto; allontanati leggermente.", ru: "Слишком громкий микрофон; отойдите чуть дальше.", ar: "إدخال الميكروفون مرتفع؛ ابتعد قليلاً.", hi: "माइक इनपुट बहुत तेज़ है; थोड़ा पीछे हटें.", id: "Input mikrofon terlalu keras; mundur sedikit.", vi: "Âm micrô quá lớn; lùi ra một chút.", th: "เสียงไมโครโฟนดังเกินไป ถอยออกเล็กน้อย")
        }
    }

    static func audioQualityMeterTitle(_ kind: AudioQualityMeterKind, language: AppLanguage) -> String {
        switch kind {
        case .inputVolume:
            return pick(language, zh: "输入音量", en: "Input Level", ja: "入力音量", ko: "입력 음량", fr: "Niveau d’entrée", de: "Eingangspegel", es: "Nivel de entrada", pt: "Volume de entrada", it: "Volume ingresso", ru: "Уровень входа", ar: "مستوى الإدخال", hi: "इनपुट स्तर", id: "Level input", vi: "Âm lượng vào", th: "ระดับเสียงเข้า")
        case .backgroundNoise:
            return pick(language, zh: "环境噪音", en: "Noise", ja: "環境ノイズ", ko: "주변 소음", fr: "Bruit ambiant", de: "Umgebungsgeräusch", es: "Ruido ambiente", pt: "Ruído ambiente", it: "Rumore ambiente", ru: "Шум", ar: "ضوضاء", hi: "शोर", id: "Kebisingan", vi: "Nhiễu nền", th: "เสียงรบกวน")
        }
    }

    private static func pick(
        _ language: AppLanguage,
        zh: String,
        en: String,
        ja: String,
        ko: String,
        fr: String,
        de: String,
        es: String,
        pt: String,
        it: String,
        ru: String,
        ar: String,
        hi: String,
        id: String,
        vi: String,
        th: String
    ) -> String {
        switch language {
        case .system, .english: en
        case .simplifiedChinese: zh
        case .japanese: ja
        case .korean: ko
        case .french: fr
        case .german: de
        case .spanish: es
        case .portuguese: pt
        case .italian: it
        case .russian: ru
        case .arabic: ar
        case .hindi: hi
        case .indonesian: id
        case .vietnamese: vi
        case .thai: th
        }
    }
}

private struct StatusLabels: Equatable {
    let shortTitle: String
    let menuTitle: String
    let toolTip: String
    let canCancel: Bool

    init(shortTitle: String, menuTitle: String? = nil, toolTip: String, canCancel: Bool) {
        self.shortTitle = shortTitle
        self.menuTitle = menuTitle ?? shortTitle
        self.toolTip = toolTip
        self.canCancel = canCancel
    }
}

private struct Labels: Equatable {
    let startVoiceInput: String
    let chooseModeAndStart: String
    let settingsAndAPI: String
    let interfaceLanguage: String
    let followSystem: String
    let quitSpeakMore: String
    let statusPrefix: String
    let autoMode: String
    let dictateMode: String
    let translateMode: String
    let polishMode: String
    let askSelectedTextMode: String
    let ready: StatusLabels
    let listening: StatusLabels
    let recognizing: StatusLabels
    let refining: StatusLabels
    let inserting: StatusLabels
    let noInput: StatusLabels
    let needsAttention: StatusLabels

    init(language: AppLanguage) {
        let app = AppBrand.englishName
        switch language {
        case .simplifiedChinese:
            self.init(
                startVoiceInput: "开始语音输入",
                chooseModeAndStart: "选择模式并开始",
                settingsAndAPI: "设置 / 更换 API...",
                interfaceLanguage: "界面语言",
                followSystem: "跟随系统",
                quitSpeakMore: "退出 \(app)",
                statusPrefix: "状态：",
                autoMode: "自动模式",
                dictateMode: "直接听写",
                translateMode: "翻译模式",
                polishMode: "润色模式",
                askSelectedTextMode: "对选中文字提问",
                ready: .init(shortTitle: "就绪", toolTip: "\(AppBrand.fullName) 正在运行", canCancel: false),
                listening: .init(shortTitle: "说话中", toolTip: "按住 Control 说话，松开后整理", canCancel: true),
                recognizing: .init(shortTitle: "识别中", toolTip: "\(app) 正在等待语音识别结果", canCancel: true),
                refining: .init(shortTitle: "整理中", toolTip: "\(app) 正在整理、翻译或修正文本", canCancel: true),
                inserting: .init(shortTitle: "写入中", toolTip: "\(app) 正在写入当前输入框", canCancel: true),
                noInput: .init(shortTitle: "无输入", menuTitle: "没有检测到输入", toolTip: "\(app) 没有检测到语音", canCancel: false),
                needsAttention: .init(shortTitle: "需要处理", toolTip: "\(app) 需要你处理权限或 API 问题", canCancel: true)
            )
        case .english, .system:
            self.init(
                startVoiceInput: "Start Voice Input",
                chooseModeAndStart: "Choose a mode",
                settingsAndAPI: "Settings / API...",
                interfaceLanguage: "Interface Language",
                followSystem: "Follow System",
                quitSpeakMore: "Quit \(app)",
                statusPrefix: "Status: ",
                autoMode: "Auto Mode",
                dictateMode: "Dictation",
                translateMode: "Translation",
                polishMode: "Polish",
                askSelectedTextMode: "Ask Selected Text",
                ready: .init(shortTitle: "Ready", toolTip: "\(AppBrand.fullName) is running", canCancel: false),
                listening: .init(shortTitle: "Listening", toolTip: "Hold Control to speak; release to finish", canCancel: true),
                recognizing: .init(shortTitle: "Recognizing", toolTip: "\(app) is finishing speech recognition", canCancel: true),
                refining: .init(shortTitle: "Refining", toolTip: "\(app) is cleaning, translating, or polishing text", canCancel: true),
                inserting: .init(shortTitle: "Inserting", toolTip: "\(app) is writing into the active field", canCancel: true),
                noInput: .init(shortTitle: "No Input", toolTip: "\(app) did not detect speech", canCancel: false),
                needsAttention: .init(shortTitle: "Needs Attention", toolTip: "\(app) needs permissions or API setup", canCancel: true)
            )
        case .japanese:
            self.init(
                startVoiceInput: "音声入力を開始",
                chooseModeAndStart: "モードを選択",
                settingsAndAPI: "設定 / API...",
                interfaceLanguage: "表示言語",
                followSystem: "システムに従う",
                quitSpeakMore: "\(app)を終了",
                statusPrefix: "状態：",
                autoMode: "自動モード",
                dictateMode: "音声入力",
                translateMode: "翻訳",
                polishMode: "文章を整える",
                askSelectedTextMode: "選択テキストに質問",
                ready: .init(shortTitle: "準備完了", toolTip: "\(app) は動作中です", canCancel: false),
                listening: .init(shortTitle: "聞き取り中", toolTip: "Control を押したまま話し、離すと完了します", canCancel: true),
                recognizing: .init(shortTitle: "認識中", toolTip: "\(app) が音声認識を完了しています", canCancel: true),
                refining: .init(shortTitle: "整理中", toolTip: "\(app) がテキストを整理しています", canCancel: true),
                inserting: .init(shortTitle: "挿入中", toolTip: "\(app) が現在の入力欄に書き込んでいます", canCancel: true),
                noInput: .init(shortTitle: "入力なし", toolTip: "\(app) は音声を検出しませんでした", canCancel: false),
                needsAttention: .init(shortTitle: "確認が必要", toolTip: "\(app) の権限または API 設定を確認してください", canCancel: true)
            )
        case .korean:
            self.init(
                startVoiceInput: "음성 입력 시작",
                chooseModeAndStart: "모드 선택",
                settingsAndAPI: "설정 / API...",
                interfaceLanguage: "인터페이스 언어",
                followSystem: "시스템 따르기",
                quitSpeakMore: "\(app) 종료",
                statusPrefix: "상태: ",
                autoMode: "자동 모드",
                dictateMode: "받아쓰기",
                translateMode: "번역",
                polishMode: "다듬기",
                askSelectedTextMode: "선택한 텍스트 질문",
                ready: .init(shortTitle: "준비됨", toolTip: "\(app)이 실행 중입니다", canCancel: false),
                listening: .init(shortTitle: "듣는 중", toolTip: "Control을 누른 채 말하고 놓으면 끝납니다", canCancel: true),
                recognizing: .init(shortTitle: "인식 중", toolTip: "\(app)이 음성 인식을 마무리하고 있습니다", canCancel: true),
                refining: .init(shortTitle: "정리 중", toolTip: "\(app)이 텍스트를 정리하고 있습니다", canCancel: true),
                inserting: .init(shortTitle: "입력 중", toolTip: "\(app)이 현재 입력칸에 쓰고 있습니다", canCancel: true),
                noInput: .init(shortTitle: "입력 없음", toolTip: "\(app)이 음성을 감지하지 못했습니다", canCancel: false),
                needsAttention: .init(shortTitle: "확인 필요", toolTip: "\(app)의 권한 또는 API 설정을 확인하세요", canCancel: true)
            )
        case .french:
            self.init(
                startVoiceInput: "Démarrer la saisie vocale",
                chooseModeAndStart: "Choisir un mode",
                settingsAndAPI: "Réglages / API...",
                interfaceLanguage: "Langue de l'interface",
                followSystem: "Suivre le système",
                quitSpeakMore: "Quitter \(app)",
                statusPrefix: "État : ",
                autoMode: "Mode auto",
                dictateMode: "Dictée",
                translateMode: "Traduction",
                polishMode: "Amélioration",
                askSelectedTextMode: "Question sur texte sélectionné",
                ready: .init(shortTitle: "Prêt", toolTip: "\(app) est en cours d'exécution", canCancel: false),
                listening: .init(shortTitle: "Écoute", toolTip: "Maintenez Control pour parler, relâchez pour terminer", canCancel: true),
                recognizing: .init(shortTitle: "Reconnaissance", toolTip: "\(app) termine la reconnaissance vocale", canCancel: true),
                refining: .init(shortTitle: "Traitement", toolTip: "\(app) traite le texte", canCancel: true),
                inserting: .init(shortTitle: "Insertion", toolTip: "\(app) écrit dans le champ actif", canCancel: true),
                noInput: .init(shortTitle: "Aucune entrée", toolTip: "\(app) n'a détecté aucune voix", canCancel: false),
                needsAttention: .init(shortTitle: "Attention requise", toolTip: "\(app) nécessite des autorisations ou une configuration API", canCancel: true)
            )
        case .german:
            self.init(
                startVoiceInput: "Spracheingabe starten",
                chooseModeAndStart: "Modus wählen",
                settingsAndAPI: "Einstellungen / API...",
                interfaceLanguage: "Oberflächensprache",
                followSystem: "Systemstandard",
                quitSpeakMore: "\(app) beenden",
                statusPrefix: "Status: ",
                autoMode: "Automatisch",
                dictateMode: "Diktat",
                translateMode: "Übersetzung",
                polishMode: "Überarbeiten",
                askSelectedTextMode: "Markierten Text fragen",
                ready: .init(shortTitle: "Bereit", toolTip: "\(app) läuft", canCancel: false),
                listening: .init(shortTitle: "Hört zu", toolTip: "Control gedrückt halten und sprechen, loslassen zum Beenden", canCancel: true),
                recognizing: .init(shortTitle: "Erkennung", toolTip: "\(app) schließt die Spracherkennung ab", canCancel: true),
                refining: .init(shortTitle: "Überarbeitung", toolTip: "\(app) überarbeitet den Text", canCancel: true),
                inserting: .init(shortTitle: "Einfügen", toolTip: "\(app) schreibt in das aktive Feld", canCancel: true),
                noInput: .init(shortTitle: "Keine Eingabe", toolTip: "\(app) hat keine Sprache erkannt", canCancel: false),
                needsAttention: .init(shortTitle: "Aufmerksamkeit nötig", toolTip: "\(app) benötigt Berechtigungen oder API-Einstellungen", canCancel: true)
            )
        case .spanish:
            self.init(
                startVoiceInput: "Iniciar entrada de voz",
                chooseModeAndStart: "Elegir modo",
                settingsAndAPI: "Ajustes / API...",
                interfaceLanguage: "Idioma de interfaz",
                followSystem: "Seguir sistema",
                quitSpeakMore: "Salir de \(app)",
                statusPrefix: "Estado: ",
                autoMode: "Modo automático",
                dictateMode: "Dictado",
                translateMode: "Traducción",
                polishMode: "Pulir",
                askSelectedTextMode: "Preguntar sobre texto seleccionado",
                ready: .init(shortTitle: "Listo", toolTip: "\(app) está en ejecución", canCancel: false),
                listening: .init(shortTitle: "Escuchando", toolTip: "Mantén Control para hablar y suelta para terminar", canCancel: true),
                recognizing: .init(shortTitle: "Reconociendo", toolTip: "\(app) está terminando el reconocimiento de voz", canCancel: true),
                refining: .init(shortTitle: "Refinando", toolTip: "\(app) está refinando el texto", canCancel: true),
                inserting: .init(shortTitle: "Insertando", toolTip: "\(app) está escribiendo en el campo activo", canCancel: true),
                noInput: .init(shortTitle: "Sin entrada", toolTip: "\(app) no detectó voz", canCancel: false),
                needsAttention: .init(shortTitle: "Requiere atención", toolTip: "\(app) necesita permisos o configuración de API", canCancel: true)
            )
        case .portuguese:
            self.init(
                startVoiceInput: "Iniciar entrada por voz",
                chooseModeAndStart: "Escolher modo",
                settingsAndAPI: "Configurações / API...",
                interfaceLanguage: "Idioma da interface",
                followSystem: "Seguir sistema",
                quitSpeakMore: "Sair do \(app)",
                statusPrefix: "Status: ",
                autoMode: "Modo automático",
                dictateMode: "Ditado",
                translateMode: "Tradução",
                polishMode: "Polir",
                askSelectedTextMode: "Perguntar sobre texto selecionado",
                ready: .init(shortTitle: "Pronto", toolTip: "\(app) está em execução", canCancel: false),
                listening: .init(shortTitle: "Ouvindo", toolTip: "Segure Control para falar e solte para finalizar", canCancel: true),
                recognizing: .init(shortTitle: "Reconhecendo", toolTip: "\(app) está concluindo o reconhecimento de voz", canCancel: true),
                refining: .init(shortTitle: "Refinando", toolTip: "\(app) está refinando o texto", canCancel: true),
                inserting: .init(shortTitle: "Inserindo", toolTip: "\(app) está escrevendo no campo ativo", canCancel: true),
                noInput: .init(shortTitle: "Sem entrada", toolTip: "\(app) não detectou fala", canCancel: false),
                needsAttention: .init(shortTitle: "Precisa de atenção", toolTip: "\(app) precisa de permissões ou configuração de API", canCancel: true)
            )
        case .italian:
            self.init(
                startVoiceInput: "Avvia input vocale",
                chooseModeAndStart: "Scegli modalità",
                settingsAndAPI: "Impostazioni / API...",
                interfaceLanguage: "Lingua interfaccia",
                followSystem: "Segui sistema",
                quitSpeakMore: "Esci da \(app)",
                statusPrefix: "Stato: ",
                autoMode: "Modalità automatica",
                dictateMode: "Dettatura",
                translateMode: "Traduzione",
                polishMode: "Rifinitura",
                askSelectedTextMode: "Chiedi sul testo selezionato",
                ready: .init(shortTitle: "Pronto", toolTip: "\(app) è in esecuzione", canCancel: false),
                listening: .init(shortTitle: "In ascolto", toolTip: "Tieni premuto Control per parlare, rilascia per terminare", canCancel: true),
                recognizing: .init(shortTitle: "Riconoscimento", toolTip: "\(app) sta completando il riconoscimento vocale", canCancel: true),
                refining: .init(shortTitle: "Rifinitura", toolTip: "\(app) sta rifinendo il testo", canCancel: true),
                inserting: .init(shortTitle: "Inserimento", toolTip: "\(app) sta scrivendo nel campo attivo", canCancel: true),
                noInput: .init(shortTitle: "Nessun input", toolTip: "\(app) non ha rilevato voce", canCancel: false),
                needsAttention: .init(shortTitle: "Richiede attenzione", toolTip: "\(app) richiede permessi o configurazione API", canCancel: true)
            )
        case .russian:
            self.init(
                startVoiceInput: "Начать голосовой ввод",
                chooseModeAndStart: "Выбрать режим",
                settingsAndAPI: "Настройки / API...",
                interfaceLanguage: "Язык интерфейса",
                followSystem: "Как в системе",
                quitSpeakMore: "Выйти из \(app)",
                statusPrefix: "Статус: ",
                autoMode: "Авторежим",
                dictateMode: "Диктовка",
                translateMode: "Перевод",
                polishMode: "Улучшение",
                askSelectedTextMode: "Вопрос по выделенному тексту",
                ready: .init(shortTitle: "Готово", toolTip: "\(app) запущен", canCancel: false),
                listening: .init(shortTitle: "Слушаю", toolTip: "Удерживайте Control, чтобы говорить; отпустите для завершения", canCancel: true),
                recognizing: .init(shortTitle: "Распознавание", toolTip: "\(app) завершает распознавание речи", canCancel: true),
                refining: .init(shortTitle: "Обработка", toolTip: "\(app) обрабатывает текст", canCancel: true),
                inserting: .init(shortTitle: "Вставка", toolTip: "\(app) пишет в активное поле", canCancel: true),
                noInput: .init(shortTitle: "Нет ввода", toolTip: "\(app) не обнаружил речь", canCancel: false),
                needsAttention: .init(shortTitle: "Требуется внимание", toolTip: "\(app) нужны разрешения или настройки API", canCancel: true)
            )
        case .arabic:
            self.init(
                startVoiceInput: "بدء الإدخال الصوتي",
                chooseModeAndStart: "اختر وضعًا",
                settingsAndAPI: "الإعدادات / API...",
                interfaceLanguage: "لغة الواجهة",
                followSystem: "اتباع النظام",
                quitSpeakMore: "إنهاء \(app)",
                statusPrefix: "الحالة: ",
                autoMode: "الوضع التلقائي",
                dictateMode: "إملاء",
                translateMode: "ترجمة",
                polishMode: "تحسين",
                askSelectedTextMode: "سؤال عن النص المحدد",
                ready: .init(shortTitle: "جاهز", toolTip: "\(app) قيد التشغيل", canCancel: false),
                listening: .init(shortTitle: "يستمع", toolTip: "اضغط Control للتحدث واتركه للإنهاء", canCancel: true),
                recognizing: .init(shortTitle: "يتعرف", toolTip: "\(app) ينهي التعرف على الكلام", canCancel: true),
                refining: .init(shortTitle: "يحسن", toolTip: "\(app) يحسن النص", canCancel: true),
                inserting: .init(shortTitle: "يدرج", toolTip: "\(app) يكتب في الحقل النشط", canCancel: true),
                noInput: .init(shortTitle: "لا يوجد إدخال", toolTip: "\(app) لم يكتشف كلامًا", canCancel: false),
                needsAttention: .init(shortTitle: "يتطلب انتباهًا", toolTip: "\(app) يحتاج إلى أذونات أو إعداد API", canCancel: true)
            )
        case .hindi:
            self.init(
                startVoiceInput: "वॉइस इनपुट शुरू करें",
                chooseModeAndStart: "मोड चुनें",
                settingsAndAPI: "सेटिंग्स / API...",
                interfaceLanguage: "इंटरफ़ेस भाषा",
                followSystem: "सिस्टम का पालन करें",
                quitSpeakMore: "\(app) बंद करें",
                statusPrefix: "स्थिति: ",
                autoMode: "ऑटो मोड",
                dictateMode: "डिक्टेशन",
                translateMode: "अनुवाद",
                polishMode: "सुधारें",
                askSelectedTextMode: "चुने हुए टेक्स्ट से पूछें",
                ready: .init(shortTitle: "तैयार", toolTip: "\(app) चल रहा है", canCancel: false),
                listening: .init(shortTitle: "सुन रहा है", toolTip: "बोलने के लिए Control दबाए रखें, समाप्त करने के लिए छोड़ें", canCancel: true),
                recognizing: .init(shortTitle: "पहचान रहा है", toolTip: "\(app) वॉइस पहचान पूरी कर रहा है", canCancel: true),
                refining: .init(shortTitle: "सुधार रहा है", toolTip: "\(app) टेक्स्ट सुधार रहा है", canCancel: true),
                inserting: .init(shortTitle: "डाल रहा है", toolTip: "\(app) सक्रिय फ़ील्ड में लिख रहा है", canCancel: true),
                noInput: .init(shortTitle: "कोई इनपुट नहीं", toolTip: "\(app) ने आवाज़ नहीं पहचानी", canCancel: false),
                needsAttention: .init(shortTitle: "ध्यान चाहिए", toolTip: "\(app) को अनुमति या API सेटअप चाहिए", canCancel: true)
            )
        case .indonesian:
            self.init(
                startVoiceInput: "Mulai input suara",
                chooseModeAndStart: "Pilih mode",
                settingsAndAPI: "Pengaturan / API...",
                interfaceLanguage: "Bahasa antarmuka",
                followSystem: "Ikuti sistem",
                quitSpeakMore: "Keluar \(app)",
                statusPrefix: "Status: ",
                autoMode: "Mode otomatis",
                dictateMode: "Dikte",
                translateMode: "Terjemahan",
                polishMode: "Poles",
                askSelectedTextMode: "Tanya teks terpilih",
                ready: .init(shortTitle: "Siap", toolTip: "\(app) sedang berjalan", canCancel: false),
                listening: .init(shortTitle: "Mendengarkan", toolTip: "Tahan Control untuk berbicara, lepaskan untuk selesai", canCancel: true),
                recognizing: .init(shortTitle: "Mengenali", toolTip: "\(app) sedang menyelesaikan pengenalan suara", canCancel: true),
                refining: .init(shortTitle: "Merapikan", toolTip: "\(app) sedang merapikan teks", canCancel: true),
                inserting: .init(shortTitle: "Memasukkan", toolTip: "\(app) sedang menulis ke bidang aktif", canCancel: true),
                noInput: .init(shortTitle: "Tidak ada input", toolTip: "\(app) tidak mendeteksi suara", canCancel: false),
                needsAttention: .init(shortTitle: "Perlu perhatian", toolTip: "\(app) memerlukan izin atau pengaturan API", canCancel: true)
            )
        case .vietnamese:
            self.init(
                startVoiceInput: "Bắt đầu nhập bằng giọng nói",
                chooseModeAndStart: "Chọn chế độ",
                settingsAndAPI: "Cài đặt / API...",
                interfaceLanguage: "Ngôn ngữ giao diện",
                followSystem: "Theo hệ thống",
                quitSpeakMore: "Thoát \(app)",
                statusPrefix: "Trạng thái: ",
                autoMode: "Chế độ tự động",
                dictateMode: "Đọc chính tả",
                translateMode: "Dịch",
                polishMode: "Chỉnh sửa",
                askSelectedTextMode: "Hỏi về văn bản đã chọn",
                ready: .init(shortTitle: "Sẵn sàng", toolTip: "\(app) đang chạy", canCancel: false),
                listening: .init(shortTitle: "Đang nghe", toolTip: "Giữ Control để nói, thả ra để kết thúc", canCancel: true),
                recognizing: .init(shortTitle: "Đang nhận dạng", toolTip: "\(app) đang hoàn tất nhận dạng giọng nói", canCancel: true),
                refining: .init(shortTitle: "Đang chỉnh sửa", toolTip: "\(app) đang chỉnh sửa văn bản", canCancel: true),
                inserting: .init(shortTitle: "Đang chèn", toolTip: "\(app) đang ghi vào ô đang hoạt động", canCancel: true),
                noInput: .init(shortTitle: "Không có đầu vào", toolTip: "\(app) không phát hiện giọng nói", canCancel: false),
                needsAttention: .init(shortTitle: "Cần chú ý", toolTip: "\(app) cần quyền hoặc cấu hình API", canCancel: true)
            )
        case .thai:
            self.init(
                startVoiceInput: "เริ่มป้อนข้อมูลด้วยเสียง",
                chooseModeAndStart: "เลือกโหมด",
                settingsAndAPI: "การตั้งค่า / API...",
                interfaceLanguage: "ภาษาอินเทอร์เฟซ",
                followSystem: "ตามระบบ",
                quitSpeakMore: "ออกจาก \(app)",
                statusPrefix: "สถานะ: ",
                autoMode: "โหมดอัตโนมัติ",
                dictateMode: "พิมพ์ตามเสียง",
                translateMode: "แปล",
                polishMode: "ปรับข้อความ",
                askSelectedTextMode: "ถามจากข้อความที่เลือก",
                ready: .init(shortTitle: "พร้อม", toolTip: "\(app) กำลังทำงาน", canCancel: false),
                listening: .init(shortTitle: "กำลังฟัง", toolTip: "กด Control ค้างไว้เพื่อพูด แล้วปล่อยเพื่อจบ", canCancel: true),
                recognizing: .init(shortTitle: "กำลังรู้จำ", toolTip: "\(app) กำลังจบการรู้จำเสียง", canCancel: true),
                refining: .init(shortTitle: "กำลังปรับ", toolTip: "\(app) กำลังปรับข้อความ", canCancel: true),
                inserting: .init(shortTitle: "กำลังแทรก", toolTip: "\(app) กำลังเขียนในช่องที่ใช้งานอยู่", canCancel: true),
                noInput: .init(shortTitle: "ไม่มีอินพุต", toolTip: "\(app) ตรวจไม่พบเสียงพูด", canCancel: false),
                needsAttention: .init(shortTitle: "ต้องตรวจสอบ", toolTip: "\(app) ต้องการสิทธิ์หรือการตั้งค่า API", canCancel: true)
            )
        }
    }

    private init(
        startVoiceInput: String,
        chooseModeAndStart: String,
        settingsAndAPI: String,
        interfaceLanguage: String,
        followSystem: String,
        quitSpeakMore: String,
        statusPrefix: String,
        autoMode: String,
        dictateMode: String,
        translateMode: String,
        polishMode: String,
        askSelectedTextMode: String,
        ready: StatusLabels,
        listening: StatusLabels,
        recognizing: StatusLabels,
        refining: StatusLabels,
        inserting: StatusLabels,
        noInput: StatusLabels,
        needsAttention: StatusLabels
    ) {
        self.startVoiceInput = startVoiceInput
        self.chooseModeAndStart = chooseModeAndStart
        self.settingsAndAPI = settingsAndAPI
        self.interfaceLanguage = interfaceLanguage
        self.followSystem = followSystem
        self.quitSpeakMore = quitSpeakMore
        self.statusPrefix = statusPrefix
        self.autoMode = autoMode
        self.dictateMode = dictateMode
        self.translateMode = translateMode
        self.polishMode = polishMode
        self.askSelectedTextMode = askSelectedTextMode
        self.ready = ready
        self.listening = listening
        self.recognizing = recognizing
        self.refining = refining
        self.inserting = inserting
        self.noInput = noInput
        self.needsAttention = needsAttention
    }

    func statusLabels(for status: SpeakMoreSessionStatus) -> StatusLabels {
        switch status {
        case .idle: ready
        case .listening: listening
        case .finalizing: recognizing
        case .transforming: refining
        case .inserting: ready
        case .noSpeech: noInput
        case .failed: needsAttention
        }
    }
}
