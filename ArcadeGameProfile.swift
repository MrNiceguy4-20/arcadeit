import Foundation

// ----------------------------------
// Input Mapping
// ----------------------------------

struct InputMapping: Codable, Hashable {
    var buttonAKeyCode: Int
    var buttonBKeyCode: Int
    var buttonXKeyCode: Int
    var buttonYKeyCode: Int
    var startKeyCode: Int
    var coinKeyCode: Int

    static var contraDefault: InputMapping {
        InputMapping(
            buttonAKeyCode: 0x06,
            buttonBKeyCode: 0x07,
            buttonXKeyCode: 0x08,
            buttonYKeyCode: 0x09,
            startKeyCode: 0x24,
            coinKeyCode: 0x17
        )
    }
}

// ----------------------------------
// Detected Game
// ----------------------------------

enum DetectedGameType: String, Codable {
    case contraEvolution
    case unknown
}

// ----------------------------------
// Winetricks
// ----------------------------------

enum WinetricksVerb: String, Codable, CaseIterable, Identifiable, Hashable {
    case corefonts
    case vcrun2008
    case vcrun2010
    case vcrun2015
    case d3dx9
    case dxvk
    case vkd3d

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .corefonts: return "Core Fonts"
        case .vcrun2008: return "VC++ 2008"
        case .vcrun2010: return "VC++ 2010"
        case .vcrun2015: return "VC++ 2015–2022"
        case .d3dx9: return "DirectX 9 (d3dx9)"
        case .dxvk: return "DXVK (D3D9/10/11)"
        case .vkd3d: return "VKD3D (D3D12)"
        }
    }

    var category: String {
        switch self {
        case .corefonts: return "Fonts"
        case .vcrun2008, .vcrun2010, .vcrun2015:
            return "Visual C++"
        case .d3dx9, .dxvk, .vkd3d:
            return "Graphics"
        }
    }
}

// ----------------------------------
// Game Profile
// ----------------------------------

struct ArcadeGameProfile: Identifiable, Codable, Hashable {
    let id: UUID

    var name: String
    var executablePath: String
    var workingDirectory: String
    var arguments: [String]
    var gameDirectory: String

    var notes: String?

    // Artwork
    var coverImageName: String?
    var coverImageURL: URL?

    // Display / runtime
    var forceFullscreen: Bool
    var forceWindowed: Bool
    var overrideResolution: Bool
    var resolutionWidth: Int
    var resolutionHeight: Int

    // Wine
    var usePerGamePrefix: Bool
    var winePrefixPath: String?
    var disableWineMenuBuilder: Bool
    var silentWine: Bool
    var dllOverrides: [String]

    // Winetricks
    var winetricksVerbs: Set<WinetricksVerb>
    var winetricksApplied: Bool   // ✅ REQUIRED FIELD

    // Patches / input
    var prelaunchPatches: [PrelaunchPatch]
    var inputMapping: InputMapping?

    // Detection
    var detectedGame: DetectedGameType

    init(
        id: UUID = UUID(),
        name: String,
        executablePath: String,
        workingDirectory: String,
        arguments: [String] = [],
        gameDirectory: String = "",
        notes: String? = nil,
        coverImageName: String? = nil,
        coverImageURL: URL? = nil,
        forceFullscreen: Bool = false,
        forceWindowed: Bool = false,
        overrideResolution: Bool = false,
        resolutionWidth: Int = 1280,
        resolutionHeight: Int = 720,
        usePerGamePrefix: Bool = false,
        winePrefixPath: String? = nil,
        disableWineMenuBuilder: Bool = false,
        silentWine: Bool = false,
        dllOverrides: [String] = [],
        winetricksVerbs: Set<WinetricksVerb> = [],
        winetricksApplied: Bool = false,   // ✅ DEFAULT
        prelaunchPatches: [PrelaunchPatch] = [],
        inputMapping: InputMapping? = nil,
        detectedGame: DetectedGameType = .unknown
    ) {
        self.id = id
        self.name = name
        self.executablePath = executablePath
        self.workingDirectory = workingDirectory
        self.arguments = arguments
        self.gameDirectory = gameDirectory
        self.notes = notes
        self.coverImageName = coverImageName
        self.coverImageURL = coverImageURL
        self.forceFullscreen = forceFullscreen
        self.forceWindowed = forceWindowed
        self.overrideResolution = overrideResolution
        self.resolutionWidth = resolutionWidth
        self.resolutionHeight = resolutionHeight
        self.usePerGamePrefix = usePerGamePrefix
        self.winePrefixPath = winePrefixPath
        self.disableWineMenuBuilder = disableWineMenuBuilder
        self.silentWine = silentWine
        self.dllOverrides = dllOverrides
        self.winetricksVerbs = winetricksVerbs
        self.winetricksApplied = winetricksApplied
        self.prelaunchPatches = prelaunchPatches
        self.inputMapping = inputMapping
        self.detectedGame = detectedGame
    }
}
