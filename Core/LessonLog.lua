--[[
  Mentor lesson log: recent summaries in SavedVariables for /am log review.
]]

local AM = _G.AM

local MAX_LESSON_LOG = 20
local DEFAULT_PRINT_LIMIT = 5
local SNIPPET_MAX_LEN = 100

--- Maps stored `entry.type` to chat-facing labels for /am log (storage stays raw).
local FRIENDLY_TYPE_LABELS = {
    LEVEL_MILESTONE = "Level lesson",
    mentor_explain = "Spell lesson",
    latest_learned = "New ability",
    first_known = "Ability tip",
    unknown_untracked = "New ability noticed",
}

local function FriendlyTypeLabel(technicalType)
    if not technicalType or technicalType == "" then
        return "Lesson"
    end
    return FRIENDLY_TYPE_LABELS[technicalType] or "Lesson"
end

local function LessonLogVerboseChat()
    return AM.DEBUG_LESSON_LOG == true
end

local function truncate(s, maxLen)
    if type(s) ~= "string" then
        s = s and tostring(s) or ""
    end
    maxLen = tonumber(maxLen) or 80
    if #s <= maxLen then
        return s
    end
    return string.sub(s, 1, maxLen - 3) .. "..."
end

--- Ensure AzerothMentorDB.lessonLog exists (SavedVariables root is created elsewhere).
function AM:EnsureLessonLogDB()
    if type(_G.AzerothMentorDB) ~= "table" then
        _G.AzerothMentorDB = {}
    end
    if type(AzerothMentorDB.lessonLog) ~= "table" then
        AzerothMentorDB.lessonLog = {}
    end
end

--- @param entry table fields: type, title, subtitle, body or shortText, instruction, level, timestamp, spellID optional
function AM:AddLessonLogEntry(entry)
    if type(entry) ~= "table" then
        return
    end
    self:EnsureLessonLogDB()
    local ty = entry.type
    local title = entry.title
    ty = ty and tostring(ty) or ""
    title = title and tostring(title) or ""

    local log = AzerothMentorDB.lessonLog
    local prev = log[#log]
    if prev and prev.type == ty and prev.title == title then
        return
    end

    local body = entry.body
    if body == nil or body == "" then
        body = entry.shortText
    end
    if type(body) ~= "string" then
        body = body and tostring(body) or ""
    end
    body = truncate(body, 500)

    local row = {
        type = ty,
        title = title,
        subtitle = entry.subtitle and tostring(entry.subtitle) or "",
        body = body,
        shortText = truncate(entry.shortText and tostring(entry.shortText) or body, 500),
        instruction = entry.instruction and tostring(entry.instruction) or "",
        level = tonumber(entry.level) or (UnitLevel("player") or 0),
        timestamp = tonumber(entry.timestamp) or time(),
        spellID = entry.spellID,
    }
    if entry.milestoneKey then
        row.milestoneKey = tostring(entry.milestoneKey)
    end

    log[#log + 1] = row
    while #log > MAX_LESSON_LOG do
        table.remove(log, 1)
    end
end

--- Print latest `limit` entries to chat (newest last).
--- @param limit number|nil default 5
function AM:PrintLessonLog(limit)
    self:EnsureLessonLogDB()
    limit = tonumber(limit) or DEFAULT_PRINT_LIMIT
    if limit < 1 then
        limit = DEFAULT_PRINT_LIMIT
    end
    local log = AzerothMentorDB.lessonLog
    if not log or #log == 0 then
        print("[Azeroth Mentor] No recent lessons yet. Open the mentor window for tips; level milestones are saved when you click Got it.")
        return
    end
    local verbose = LessonLogVerboseChat()
    print("[Azeroth Mentor] Recent lessons:")
    local startIdx = math.max(1, #log - limit + 1)
    local displayIdx = 0
    for i = startIdx, #log do
        displayIdx = displayIdx + 1
        local e = log[i]
        local ts = e.timestamp and date("%H:%M", e.timestamp) or "?"
        local techType = e.type and tostring(e.type) or ""
        local title = truncate(e.title or "?", 48)
        if verbose then
            local sid = e.spellID and string.format(" #%d", tonumber(e.spellID) or 0) or ""
            local lv = tonumber(e.level) or 0
            print(string.format("%d. [%s] %s | L%d%s | %s", displayIdx, ts, techType, lv, sid, title))
        else
            print(string.format("%d. [%s] %s: %s", displayIdx, ts, FriendlyTypeLabel(techType), title))
        end
        local snippet = truncate(e.body or e.shortText or "", SNIPPET_MAX_LEN)
        if snippet ~= "" then
            print("   " .. snippet)
        end
    end
end

function AM:ClearLessonLog()
    self:EnsureLessonLogDB()
    wipe(AzerothMentorDB.lessonLog)
    print("[Azeroth Mentor] Lesson log cleared.")
end
