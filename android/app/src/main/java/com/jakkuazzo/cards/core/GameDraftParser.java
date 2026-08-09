package com.jakkuazzo.cards.core;

import java.util.Locale;

/**
 * Converts the intentionally small Cards creator format into a safe, known
 * game template.  It is deliberately not an AI/code interpreter: callers get
 * one of the bundled game archetypes or a useful validation error.
 */
public final class GameDraftParser {
    public static final class Draft {
        public final String name;
        public final String template;
        public final int maximumPlayers;
        public final boolean arEnabled;
        public final String tableDesign;

        private Draft(String name, String template, int maximumPlayers, boolean arEnabled, String tableDesign) {
            this.name = name;
            this.template = template;
            this.maximumPlayers = maximumPlayers;
            this.arEnabled = arEnabled;
            this.tableDesign = tableDesign;
        }
    }

    private GameDraftParser() { }

    public static Draft parse(String input) {
        String source = input == null ? "" : input.trim();
        if (source.isEmpty()) throw new IllegalArgumentException("Describe poker, guess who, dominoes, or a prompt game.");
        String normalized = source.toLowerCase(Locale.ROOT);
        String template;
        String tableDesign;
        int defaultMax;
        boolean defaultAr;
        if (normalized.contains("domino")) { template = "dominoes"; tableDesign = "domino-yard"; defaultMax = 4; defaultAr = false; }
        else if (normalized.contains("guess who") || normalized.contains("guess-who") || normalized.contains("guess_who")) { template = "guess-who"; tableDesign = "guess-grid"; defaultMax = 2; defaultAr = false; }
        else if (normalized.contains("poker") || normalized.contains("hold'em") || normalized.contains("holdem")) { template = "poker"; tableDesign = "poker-2"; defaultMax = 4; defaultAr = true; }
        else if (hasPromptLines(source)) { template = "prompt-draw"; tableDesign = "green-classic"; defaultMax = 8; defaultAr = false; }
        else throw new IllegalArgumentException("Use poker, guess who, dominoes, or at least two prompt lines beginning with '-'.");

        int maximum = integerDirective(source, "max_user", integerDirective(source, "max_users", defaultMax));
        if (maximum < 1 || maximum > 16) throw new IllegalArgumentException("max_user must be between 1 and 16.");
        String design = stringDirective(source, "tabledesign");
        if (design != null) tableDesign = tableDesign(design);
        String ar = stringDirective(source, "ar");
        boolean arEnabled = ar == null ? defaultAr : yes(ar);
        String idea = stringDirective(source, "idea");
        String name = idea == null || idea.trim().isEmpty() ? displayName(template) : trimName(idea);
        return new Draft(name, template, maximum, arEnabled, tableDesign);
    }

    private static boolean hasPromptLines(String source) { int count = 0; for (String line : source.split("\\r?\\n")) if (line.trim().startsWith("-")) count++; return count >= 2; }
    private static int integerDirective(String source, String key, int fallback) { String value = stringDirective(source, key); if (value == null) return fallback; try { return Integer.parseInt(value.trim()); } catch (NumberFormatException error) { throw new IllegalArgumentException(key + " must be a whole number."); } }
    private static String stringDirective(String source, String key) { for (String line : source.split("\\r?\\n")) { int colon = line.indexOf(':'); if (colon <= 0) continue; if (line.substring(0, colon).trim().equalsIgnoreCase(key)) return line.substring(colon + 1).trim(); } return null; }
    private static boolean yes(String value) { String normalized = value.trim().toLowerCase(Locale.ROOT); if (normalized.equals("y") || normalized.equals("yes") || normalized.equals("true")) return true; if (normalized.equals("n") || normalized.equals("no") || normalized.equals("false")) return false; throw new IllegalArgumentException("ar must be y or n."); }
    private static String tableDesign(String value) { String normalized = value.trim().toLowerCase(Locale.ROOT).replace(".png", ""); if (normalized.equals("poker_2") || normalized.equals("poker-2")) return "poker-2"; if (normalized.equals("guess_grid") || normalized.equals("guess-grid")) return "guess-grid"; if (normalized.equals("domino_yard") || normalized.equals("domino-yard")) return "domino-yard"; if (normalized.equals("green_classic") || normalized.equals("green-classic")) return "green-classic"; throw new IllegalArgumentException("Use a bundled table design: poker-2, guess-grid, domino-yard, or green-classic."); }
    private static String displayName(String template) { if (template.equals("guess-who")) return "Guess Who Board"; if (template.equals("dominoes")) return "Double-Six Dominoes"; if (template.equals("poker")) return "Classic Pack Poker"; return "Prompt Table"; }
    private static String trimName(String value) { String name = value.trim(); return name.length() <= 48 ? name : name.substring(0, 48); }
}
