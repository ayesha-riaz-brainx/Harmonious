import 'package:slot_1_tasks/core/astrology/cosmic_checkin.dart';
import 'package:slot_1_tasks/core/astrology/zodiac_sign.dart';

/// Pre-written wellness-oriented cosmic check-ins (Mon–Sun rotation).
/// No AI — same message all day, cached after first load.
class CosmicCheckInLibrary {
  const CosmicCheckInLibrary._();

  static CosmicCheckIn resolve({
    required ZodiacSign sign,
    required DateTime date,
  }) {
    final weekdayIndex = date.weekday - 1; // 0 = Monday
    final entry = _bySign[sign]![weekdayIndex];
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return CosmicCheckIn(
      sign: sign,
      theme: entry.theme,
      relationships: entry.relationships,
      productivity: entry.productivity,
      wellness: entry.wellness,
      dateKey: dateKey,
    );
  }

  static final Map<ZodiacSign, List<_DayContent>> _bySign = {
    ZodiacSign.aries: _aries,
    ZodiacSign.taurus: _taurus,
    ZodiacSign.gemini: _gemini,
    ZodiacSign.cancer: _cancer,
    ZodiacSign.leo: _leo,
    ZodiacSign.virgo: _virgo,
    ZodiacSign.libra: _libra,
    ZodiacSign.scorpio: _scorpio,
    ZodiacSign.sagittarius: _sagittarius,
    ZodiacSign.capricorn: _capricorn,
    ZodiacSign.aquarius: _aquarius,
    ZodiacSign.pisces: _pisces,
  };
}

class _DayContent {
  const _DayContent({
    required this.theme,
    required this.relationships,
    required this.productivity,
    required this.wellness,
  });

  final String theme;
  final String relationships;
  final String productivity;
  final String wellness;
}

// Mon → Sun (7 entries each)

const _libra = [
  _DayContent(
    theme: 'Balance',
    relationships:
        "Don't try to solve everyone's problems today. Listen, then let people find their own footing.",
    productivity:
        'Finish one important thing before starting something new.',
    wellness:
        'Your body may benefit from slowing down tonight — gentle stretch, early wind-down.',
  ),
  _DayContent(
    theme: 'Harmony',
    relationships:
        'Say yes to connection, but protect quiet time. A short honest check-in beats a long debate.',
    productivity:
        'Collaborate on one task; save solo deep work for when the room is calm.',
    wellness: 'Eat at a steady pace. Skipping meals throws off your rhythm.',
  ),
  _DayContent(
    theme: 'Clarity',
    relationships:
        'If something feels unfair, name it calmly — without keeping score.',
    productivity:
        'Declutter your to-do list. Cross off two items that no longer matter.',
    wellness: 'A walk outside helps reset your nervous system.',
  ),
  _DayContent(
    theme: 'Reciprocity',
    relationships:
        'Give support where it’s welcome; ask for help where you need it.',
    productivity:
        'Batch small decisions in the morning so afternoons stay lighter.',
    wellness: 'Hydrate before coffee — your energy steadies faster.',
  ),
  _DayContent(
    theme: 'Grace',
    relationships:
        'Choose kindness over being right in low-stakes moments.',
    productivity:
        'One focused block beats scattered multitasking today.',
    wellness: 'Wind down screens 30 minutes earlier than usual.',
  ),
  _DayContent(
    theme: 'Restoration',
    relationships:
        'Quality time > quantity. One meaningful conversation is enough.',
    productivity:
        'Review the week; celebrate progress before planning Monday.',
    wellness: 'Sleep is your reset button — treat it as non-negotiable.',
  ),
  _DayContent(
    theme: 'Renewal',
    relationships:
        'Reach out to someone who makes you feel seen — keep it simple.',
    productivity:
        'Light planning only. Protect space for rest and reflection.',
    wellness: 'Move gently: yoga, stroll, or stretching — nothing punishing.',
  ),
];

const _aries = [
  _DayContent(
    theme: 'Momentum',
    relationships: 'Lead with encouragement, not urgency. Others match your pace.',
    productivity: 'Start the hardest task first — your morning fire is real.',
    wellness: 'Cool down after effort: breathe, stretch, don’t crash.',
  ),
  _DayContent(
    theme: 'Courage',
    relationships: 'Speak directly but leave room for others to respond.',
    productivity: 'Short sprints work better than marathon pushes today.',
    wellness: 'Watch caffeine late day — restlessness shows up at night.',
  ),
  _DayContent(
    theme: 'Focus',
    relationships: 'Competition is optional. Cheer someone else’s win.',
    productivity: 'One clear goal. Say no to the rest until it’s done.',
    wellness: 'Release jaw and shoulders — tension hides there.',
  ),
  _DayContent(
    theme: 'Patience',
    relationships: 'Not every battle needs you. Save energy for what matters.',
    productivity: 'Review before you send. Speed + care beats speed alone.',
    wellness: 'Eat protein with breakfast to steady your drive.',
  ),
  _DayContent(
    theme: 'Integrity',
    relationships: 'Apologize fast if you snapped — repair builds trust.',
    productivity: 'Delegate one thing you’ve been hoarding.',
    wellness: 'Even 10 minutes of movement clears mental static.',
  ),
  _DayContent(
    theme: 'Recovery',
    relationships: 'Listen more than you fix. Presence is enough.',
    productivity: 'Wrap loose ends; don’t start major new projects.',
    wellness: 'Prioritize sleep — your body recovers ambition overnight.',
  ),
  _DayContent(
    theme: 'Play',
    relationships: 'Laugh with someone. Joy refuels your fire.',
    productivity: 'Creative side projects count as productive rest.',
    wellness: 'Outdoor light + movement = best Sunday medicine.',
  ),
];

const _taurus = [
  _DayContent(
    theme: 'Steadiness',
    relationships: 'Show up reliably — small gestures land deeply today.',
    productivity: 'Slow and thorough beats rushed and redoing.',
    wellness: 'Comfort food is fine; add something fresh on the side.',
  ),
  _DayContent(
    theme: 'Grounding',
    relationships: 'Quality time at home or in nature beats crowded plans.',
    productivity: 'Block distractions. One task, one table, one hour.',
    wellness: 'Neck and lower back want gentle movement.',
  ),
  _DayContent(
    theme: 'Value',
    relationships: 'Invest in people who respect your boundaries.',
    productivity: 'Finish what you started before buying new tools.',
    wellness: 'Hydration helps more than another coffee.',
  ),
  _DayContent(
    theme: 'Sensory calm',
    relationships: 'Share a meal or walk — simple rituals connect you.',
    productivity: 'Organize your workspace; clarity follows order.',
    wellness: 'Wind down with something tactile: tea, bath, soft music.',
  ),
  _DayContent(
    theme: 'Persistence',
    relationships: 'Stubbornness softened with warmth goes far.',
    productivity: 'Progress > perfection on long-term goals.',
    wellness: 'Stretch hips and hamstrings — you hold stress there.',
  ),
  _DayContent(
    theme: 'Contentment',
    relationships: 'Gratitude texts strengthen bonds quietly.',
    productivity: 'Review finances or plans — practical care is self-care.',
    wellness: 'Early bedtime protects Monday energy.',
  ),
  _DayContent(
    theme: 'Rest',
    relationships: 'Low-key company only. Solitude is also connection.',
    productivity: 'Prep for the week; don’t over-schedule.',
    wellness: 'Cook something nourishing at an unhurried pace.',
  ),
];

const _gemini = [
  _DayContent(
    theme: 'Curiosity',
    relationships: 'Ask one good question instead of offering ten opinions.',
    productivity: 'Capture ideas quickly, then pick one to execute.',
    wellness: 'Screen breaks every hour — your mind needs air.',
  ),
  _DayContent(
    theme: 'Connection',
    relationships: 'Follow up on a message you left hanging.',
    productivity: 'Batch communication; protect focus blocks.',
    wellness: 'Walk while you think — movement unlocks clarity.',
  ),
  _DayContent(
    theme: 'Flexibility',
    relationships: 'Plans may shift. Stay light, not scattered.',
    productivity: 'Two priorities max. Everything else waits.',
    wellness: 'Breathe before replying when irritated.',
  ),
  _DayContent(
    theme: 'Learning',
    relationships: 'Teach something small; learn something small.',
    productivity: 'Read or research, then summarize in three bullets.',
    wellness: 'Limit news scroll — protect mental bandwidth.',
  ),
  _DayContent(
    theme: 'Honesty',
    relationships: 'Say what you mean without over-explaining.',
    productivity: 'Close open loops: emails, tabs, tiny tasks.',
    wellness: 'Hands and wrists deserve a stretch break.',
  ),
  _DayContent(
    theme: 'Variety',
    relationships: 'Mix social time with solo recharge.',
    productivity: 'Week review: what actually moved the needle?',
    wellness: 'Sleep routine beats late-night rabbit holes.',
  ),
  _DayContent(
    theme: 'Quiet mind',
    relationships: 'One deep conversation beats many shallow ones.',
    productivity: 'Sunday planning: short list, realistic slots.',
    wellness: 'Journal three lines — empty the mental tabs.',
  ),
];

const _cancer = [
  _DayContent(
    theme: 'Nurture',
    relationships: 'Care for others starts with checking in on yourself.',
    productivity: 'Work from a cozy setup — comfort supports focus.',
    wellness: 'Warm food and hydration soothe your system.',
  ),
  _DayContent(
    theme: 'Boundaries',
    relationships: 'It’s okay to say “not today” without guilt.',
    productivity: 'Protect morning energy for meaningful work.',
    wellness: 'Moonlit walk or soft lighting helps evening calm.',
  ),
  _DayContent(
    theme: 'Emotional honesty',
    relationships: 'Name a feeling instead of acting it out.',
    productivity: 'Creative tasks flow when you feel safe.',
    wellness: 'Limit harsh self-talk — talk like a friend.',
  ),
  _DayContent(
    theme: 'Home base',
    relationships: 'Family or chosen family time refuels you.',
    productivity: 'Tidy one corner — outer order, inner calm.',
    wellness: 'Magnesium-rich foods or tea may help sleep.',
  ),
  _DayContent(
    theme: 'Protection',
    relationships: 'Don’t absorb everyone’s mood. Return to center.',
    productivity: 'Finish a task that reduces tomorrow’s worry.',
    wellness: 'Gentle yoga or stretching before bed.',
  ),
  _DayContent(
    theme: 'Reflection',
    relationships: 'Forgive small slights — hold the big ones wisely.',
    productivity: 'Light admin only. Guard emotional energy.',
    wellness: 'Prioritize rest over productivity guilt.',
  ),
  _DayContent(
    theme: 'Soft start',
    relationships: 'Reach out to someone who feels like home.',
    productivity: 'Plan the week with buffer time built in.',
    wellness: 'Cook, rest, or create — feed your inner world.',
  ),
];

const _leo = [
  _DayContent(
    theme: 'Radiance',
    relationships: 'Celebrate others — spotlight shared feels better.',
    productivity: 'Present or perform one thing with full heart.',
    wellness: 'Heart-rate movement + cooldown, not all-out burnout.',
  ),
  _DayContent(
    theme: 'Generosity',
    relationships: 'Compliment sincerely. It costs little, means much.',
    productivity: 'Lead a meeting or initiative — visibility helps.',
    wellness: 'Watch pride-fueled overcommitment tonight.',
  ),
  _DayContent(
    theme: 'Creative fire',
    relationships: 'Play together — fun strengthens loyalty.',
    productivity: 'Make something visible: draft, demo, share.',
    wellness: 'Spine and upper back want posture breaks.',
  ),
  _DayContent(
    theme: 'Dignity',
    relationships: 'Disagree without drama. Keep your crown on.',
    productivity: 'Delegate tasks that drain your joy.',
    wellness: 'Sunlight + walk = natural mood lift.',
  ),
  _DayContent(
    theme: 'Warmth',
    relationships: 'Check on someone who’s been quiet.',
    productivity: 'Batch ego-heavy tasks early; coast later.',
    wellness: 'Eat regularly — empty stomach shortens patience.',
  ),
  _DayContent(
    theme: 'Gratitude',
    relationships: 'Thank people who showed up for you this week.',
    productivity: 'Review wins before planning next steps.',
    wellness: 'Screen-free hour before sleep.',
  ),
  _DayContent(
    theme: 'Joy',
    relationships: 'Social time yes; performative time no.',
    productivity: 'Sunday is for inspiration, not pressure.',
    wellness: 'Dance, laugh, or sing — release stored tension.',
  ),
];

const _virgo = [
  _DayContent(
    theme: 'Precision',
    relationships: 'Help with specifics, not unsolicited fixes.',
    productivity: 'One detailed task done well > five half-done.',
    wellness: 'Digestive calm: regular meals, less grazing.',
  ),
  _DayContent(
    theme: 'Service',
    relationships: 'Offer practical support — a ride, a list, a reminder.',
    productivity: 'Clean inbox or desk; mental clutter drops.',
    wellness: 'Perfectionism relaxes with a 80% good-enough rule.',
  ),
  _DayContent(
    theme: 'Analysis',
    relationships: 'Listen fully before problem-solving.',
    productivity: 'Document a process you repeat often.',
    wellness: 'Neck stretches between screen sessions.',
  ),
  _DayContent(
    theme: 'Health habits',
    relationships: 'Suggest a walk instead of another coffee chat.',
    productivity: 'Health admin: appointments, refills, meal prep.',
    wellness: 'Sleep schedule consistency matters more than hacks.',
  ),
  _DayContent(
    theme: 'Release',
    relationships: 'Let small imperfections in others slide.',
    productivity: 'Ship version 1. Iterate tomorrow.',
    wellness: 'Abdominal breathing calms overthinking.',
  ),
  _DayContent(
    theme: 'Review',
    relationships: 'Appreciate out loud — you notice details others miss.',
    productivity: 'Weekly audit: keep, cut, delegate.',
    wellness: 'Early night beats late “just one more” tasks.',
  ),
  _DayContent(
    theme: 'Ease',
    relationships: 'Be off-duty helpfulness. Just be present.',
    productivity: 'Minimal Sunday to-do. Rest is productive.',
    wellness: 'Nature or hands-on hobby — no metrics required.',
  ),
];

const _scorpio = [
  _DayContent(
    theme: 'Depth',
    relationships: 'Go deep with one person, not wide with many.',
    productivity: 'Research thoroughly, then act decisively.',
    wellness: 'Intense emotions need movement or journaling.',
  ),
  _DayContent(
    theme: 'Truth',
    relationships: 'Honesty lands when timing and tone match.',
    productivity: 'Cut a hidden time-waster today.',
    wellness: 'Limit substances that spike then crash mood.',
  ),
  _DayContent(
    theme: 'Focus',
    relationships: 'Jealousy is data — ask what you really need.',
    productivity: 'Private focus block: no interruptions.',
    wellness: 'Pelvic/hip stretches release stored tension.',
  ),
  _DayContent(
    theme: 'Transformation',
    relationships: 'Let a grudge go if it’s costing you peace.',
    productivity: 'Finish something you’ve avoided.',
    wellness: 'Water + electrolytes support steady energy.',
  ),
  _DayContent(
    theme: 'Power',
    relationships: 'Use influence to uplift, not control.',
    productivity: 'Strategic work > busy work.',
    wellness: 'Wind-down ritual signals safety to your body.',
  ),
  _DayContent(
    theme: 'Renewal',
    relationships: 'Vulnerability with trusted people heals.',
    productivity: 'Reflect on what to release next week.',
    wellness: 'Sleep is non-negotiable for emotional balance.',
  ),
  _DayContent(
    theme: 'Stillness',
    relationships: 'Solitude recharges — communicate that need.',
    productivity: 'Light planning; protect inner quiet.',
    wellness: 'Meditation, bath, or dark room — pick one.',
  ),
];

const _sagittarius = [
  _DayContent(
    theme: 'Expansion',
    relationships: 'Share optimism without preaching.',
    productivity: 'Learn something new, apply one takeaway today.',
    wellness: 'Outdoor time beats another hour indoors.',
  ),
  _DayContent(
    theme: 'Honesty',
    relationships: 'Direct words + kindness = your superpower.',
    productivity: 'Big-picture planning; avoid tiny rabbit holes.',
    wellness: 'Hips and thighs want stretching after sitting.',
  ),
  _DayContent(
    theme: 'Adventure',
    relationships: 'Invite someone on a walk or mini outing.',
    productivity: 'Batch errands or travel efficiently.',
    wellness: 'Try a new healthy recipe — novelty motivates.',
  ),
  _DayContent(
    theme: 'Perspective',
    relationships: 'Assume good intent until proven otherwise.',
    productivity: 'Teach, write, or explain — clarity follows.',
    wellness: 'Moderate alcohol/sugar — mood swings follow excess.',
  ),
  _DayContent(
    theme: 'Freedom',
    relationships: 'Space in relationships keeps them alive.',
    productivity: 'Say no to one obligation that drains you.',
    wellness: 'Movement with music lifts spirits fast.',
  ),
  _DayContent(
    theme: 'Gratitude',
    relationships: 'Reconnect with someone far away.',
    productivity: 'Review goals — adjust, don’t abandon.',
    wellness: 'Rest legs that carried you through the week.',
  ),
  _DayContent(
    theme: 'Wonder',
    relationships: 'Philosophical chat over forced small talk.',
    productivity: 'Sunday vision board or journal — dream allowed.',
    wellness: 'Explore: hike, museum, or new neighborhood.',
  ),
];

const _capricorn = [
  _DayContent(
    theme: 'Structure',
    relationships: 'Reliability is love — show up on time.',
    productivity: 'Time-block your top three priorities.',
    wellness: 'Knees and joints appreciate warm-up before work.',
  ),
  _DayContent(
    theme: 'Discipline',
    relationships: 'Work talk later; be human first.',
    productivity: 'Eat the frog early. Reward after.',
    wellness: 'Don’t skip meals for meetings.',
  ),
  _DayContent(
    theme: 'Ambition',
    relationships: 'Mentor or ask for mentorship — both help.',
    productivity: 'Long-term step > short-term busywork.',
    wellness: 'Schedule breaks — grind without rest backfires.',
  ),
  _DayContent(
    theme: 'Pragmatism',
    relationships: 'Actions speak louder than promises today.',
    productivity: 'Fix one system: files, budget, calendar.',
    wellness: 'Lower back care: stand, stretch, walk.',
  ),
  _DayContent(
    theme: 'Patience',
    relationships: 'Others move slower — adjust expectations.',
    productivity: 'Progress metrics > perfection metrics.',
    wellness: 'Magnesium or warm shower aids sleep.',
  ),
  _DayContent(
    theme: 'Legacy',
    relationships: 'Thank people who helped your climb.',
    productivity: 'Weekly review: what to continue, stop, start.',
    wellness: 'Disconnect from work email tonight.',
  ),
  _DayContent(
    theme: 'Rest',
    relationships: 'Family or close circle — keep it simple.',
    productivity: 'Prep Monday lightly; don’t over-plan Sunday.',
    wellness: 'Permission to do nothing is earned, not guilty.',
  ),
];

const _aquarius = [
  _DayContent(
    theme: 'Innovation',
    relationships: 'Brainstorm with someone who thinks differently.',
    productivity: 'Try a new workflow for one recurring task.',
    wellness: 'Circulation: stand desk, walk breaks, ankles roll.',
  ),
  _DayContent(
    theme: 'Community',
    relationships: 'Group cause > solo rant. Channel energy outward.',
    productivity: 'Automate or template something repetitive.',
    wellness: 'Nervous system likes predictable sleep times.',
  ),
  _DayContent(
    theme: 'Detachment',
    relationships: 'Observe before reacting — space helps wisdom.',
    productivity: 'Future-you will thank documented notes.',
    wellness: 'Limit chaotic news; curate inputs.',
  ),
  _DayContent(
    theme: 'Authenticity',
    relationships: 'Weird is welcome. Match with your people.',
    productivity: 'Experiment; fail small, learn fast.',
    wellness: 'Calves and ankles — walk or stretch.',
  ),
  _DayContent(
    theme: 'Vision',
    relationships: 'Share an idea; invite collaboration, not debate.',
    productivity: 'Align tasks with values, not just urgency.',
    wellness: 'Hydrate — mental speed needs physical fuel.',
  ),
  _DayContent(
    theme: 'Humanity',
    relationships: 'Random kindness counts.',
    productivity: 'Review impact, not just output.',
    wellness: 'Social recharge + solo recharge both needed.',
  ),
  _DayContent(
    theme: 'Reset',
    relationships: 'Digital detox hour with someone present.',
    productivity: 'Sunday ideas only — execution waits for Monday.',
    wellness: 'Cold air or cold shower if you tolerate it — alert calm.',
  ),
];

const _pisces = [
  _DayContent(
    theme: 'Intuition',
    relationships: 'Trust gut on who to open up to today.',
    productivity: 'Creative flow morning; admin afternoon.',
    wellness: 'Boundaries with energy vampires — gentle but firm.',
  ),
  _DayContent(
    theme: 'Compassion',
    relationships: 'Empathy yes; absorbing others’ pain no.',
    productivity: 'Music or art breaks restore focus.',
    wellness: 'Feet and lymph — walk, massage, elevate.',
  ),
  _DayContent(
    theme: 'Dreams',
    relationships: 'Share a hope without needing immediate proof.',
    productivity: 'Visualize outcome, then one concrete step.',
    wellness: 'Limit escapism that numbs instead of heals.',
  ),
  _DayContent(
    theme: 'Flow',
    relationships: 'Water metaphors help: go around obstacles.',
    productivity: 'Flexible schedule beats rigid grind.',
    wellness: 'Swim, shower, or hydrate — water soothes you.',
  ),
  _DayContent(
    theme: 'Sensitivity',
    relationships: 'Quiet honesty > passive withdrawal.',
    productivity: 'Protect morning from harsh inputs.',
    wellness: 'Sleep mask or dark room supports deep rest.',
  ),
  _DayContent(
    theme: 'Healing',
    relationships: 'Forgive yourself for unfinished emotional work.',
    productivity: 'Gentle closure on open threads.',
    wellness: 'Rest without storyline — just be tired.',
  ),
  _DayContent(
    theme: 'Spirit',
    relationships: 'Prayer, poetry, or nature — connect your way.',
    productivity: 'Sunday dreaming is allowed.',
    wellness: 'Salt bath or warm drink — ritual over rush.',
  ),
];
