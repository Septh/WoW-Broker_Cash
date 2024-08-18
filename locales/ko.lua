-- Environnement
-- GLOBALS: LibStub
local addonName, addonTable = ...
local L = LibStub('AceLocale-3.0'):NewLocale(addonName, 'koKR')
if not L then
  return
end

-- Main tooltip
L['Name'] = '이름'
L['Cash'] = '현금'
L['Total'] = '총계'

-- Sub tooltip
L['RECORDED_SINCE'] = '> %s부터 기록됨'
L['LAST_SAVED'] = '> 마지막 저장 날짜: %s'
L['DATE_FORMAT'] = '%x'
L['DATE_TIME_FORMAT'] = '%x %p %X'
L['Current Session'] = '현재 세션'
L['Today'] = '오늘'
L['This week'] = '이번 주'
L['This month'] = '이번 달'
L['This year'] = '올해'
L['Ever'] = '전체 기간'

-- Options panel
L['Options'] = '옵션'

L['OPTIONS_GENERAL'] = '일반'
L['OPTS_SESSION_THRESHOLD'] = '세션 기준 시간'
L['OPTS_SESSION_THRESHOLD_DESC'] = '같은 캐릭터로 로그아웃 후 이 시간(초) 내에 다시 로그인하면 "세션" 통계가 초기화되지 않습니다. 자세한 내용은 문서를 참조하세요.'

L['OPTIONS_LDB'] = 'LDB 표시'
L['OPTS_HIGHLIGHT_LDB'] = '마우스 오버 시 LDB 아이콘 강조 표시'
L['OPTS_HIGHLIGHT_LDB_DESC'] = 'LDB 디스플레이 자체가 하지 않는 경우.'
L['OPTS_SMALL_PARTS'] = '동전 및 은화 표시'
L['OPTS_SMALL_PARTS_DESC'] = '금액이 0인 경우에도 표시됩니다.'
L['OPTS_HIDE_MINIMAP_BUTTON'] = '미니맵 버튼 숨기기'
L['OPTS_TEXT_LDB'] = '표시할 텍스트'

L['OPTIONS_MENU'] = '드롭다운 메뉴'
L['OPTS_DISABLE_IN_COMBAT'] = '전투 중 비활성화'
L['OPTS_DISABLE_IN_COMBAT_DESC'] = '전투 중 메뉴 표시를 방지합니다.'
L['Show Details'] = '세부 정보 표시'
L['OPTS_SHOW_DETAILS_DESC'] = '서버와 캐릭터에 마우스를 올리면 추가 세부 정보를 표시하는 보조 툴팁을 표시합니다.'

L['Characters'] = '캐릭터'
L['OPTS_CHARACTERS_INFO_1'] = '아래 목록에서 하나 이상의 캐릭터를 선택한 다음, 수행할 작업을 선택하세요:'
L['OPTS_CHARACTERS_INFO_2'] = '캐릭터의 통계를 0으로 초기화하지만 데이터베이스에는 남아 있습니다.'
L['OPTS_CHARACTERS_INFO_3'] = '캐릭터의 통계를 데이터베이스에서 삭제합니다. 현재 캐릭터는 삭제할 수 없습니다.'
L['OPTS_CHARACTERS_INFO_4'] = '경고: 이 작업은 되돌릴 수 없습니다!'
L['Reset'] = '초기화'
L['Delete'] = '삭제'
L['Notice'] = '알림'
L['NUMSELECTED_0'] = '선택된 항목 없음'
L['NUMSELECTED_1'] = '1개 선택됨'
L['NUMSELECTED_X'] = '%d개 선택됨'
L['RESET_TOON'] = '이 캐릭터 초기화:'
L['RESET_TOONS'] = '%d개 캐릭터 초기화:'
L['DELETE_TOON'] = '이 캐릭터 삭제:'
L['DELETE_TOONS'] = '%d개 캐릭터 삭제:'
L['Are you sure?'] = '정말 확실합니까?'

L['WoW Token'] = 'WoW 토큰'
L['Guild Bank'] = '길드 은행'
L['Warband Bank'] = '전투부대 은행'
