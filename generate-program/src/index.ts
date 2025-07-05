import { OpenAI } from 'openai'

interface Program {
  nom: string
  date: string
  commentaire: string
  exercices: {
    type: string
    subType: string
    series: string
    distance: string
    duration: string
    repetitions: string
    restTime: string
    intensity: 'Faible' | 'Moderee' | 'Elevee'
    accompli: boolean
  }[]
}

interface BodyIn {
  uid: string
  objectif?: string
  date?: string
  stats?: any
}

interface BatchBody extends BodyIn {
  range: 'week' | 'month'
  startDate?: string
}
const CHUNK = 15 // nombre max de jours par requête IA

/* ───────────────────────── HELPERS ───────────────────────── */

const formatDate = (d: Date | string) =>
  (typeof d === 'string' ? new Date(d) : d).toISOString().split('T')[0]

const addDays = (d: Date | string, nb: number) => {
  const x = typeof d === 'string' ? new Date(d) : new Date(d)
  x.setDate(x.getDate() + nb)
  return formatDate(x)
}
const MODEL = "deepseek/deepseek-chat:free"

// Prompt journalier
function buildPrompt(stats: any, objectif: string, body: BodyIn): string {
  const selectedDate = body.date || new Date().toISOString().split('T')[0]
  return `
Tu es un coach sportif IA. En t'appuyant sur les statistiques JSON suivantes
et l'objectif **[${objectif}]**, genere **un programme au format JSON strict**.

Types d'exercices autorises :
- Street Workout
- Course
- Cardio libre
- Shadow Boxing
- Repos actif
- Plyometrie
- Renfo avec charges

Regles SUR LES SOUS-TYPES :
| Type                  | Sous-types autorises (exactement UNE valeur)               |
|-----------------------|------------------------------------------------------------|
| Street Workout        | Pompes • Tractions • Dips • Abdos • Squats • Fentes • Gainage • Burpees • Mountain Climbers • Planche • Superman • Jump Squats |
| Plyometrie            | Sauts sur boite • Sauts lateraux • Sauts groupes • Skaters • Burpees sautes |
| Renfo avec charges    | Developpe couche • Squat barre • Souleve de terre • Rowing haltere • Developpe militaire • Curl biceps • Extension triceps |
| Course                | Sprint • Endurance • Fractionne • Montee de cote • Descente |
| Shadow Boxing         | Classique • Avec elastiques • Avec poids • Defense / Esquives • Travail vitesse |
| Repos actif           | Marche lente • Etirements • Respiration • Mobilite • Roulements d\'epaules • Rotation de hanches |

Regles supplementaires :
- Chaque sous-type d'un meme type ne doit apparaitre qu'une seule fois.
- Utilise UNIQUEMENT les intensites : "Faible", "Moderee", "Elevee".
- Toutes les durees **restTime** sont en secondes, **duration** en minutes si numeriques.
- NE RENVOIE QUE le JSON, encadre par \`\`\`json … \`\`\`.

Exemple :
\`\`\`json
{
  "nom": "Programme IA – ${selectedDate}",
  "date": "${selectedDate}",
  "commentaire": "Programme oriente puissance & cardio",
  "exercices": [
    {
      "type": "Street Workout",
      "subType": "Pompes",
      "series": "4",
      "duration": "",
      "repetitions": "15",
      "restTime": "60",
      "intensity": "Elevee",
      "accompli": false
    }
  ]
}
\`\`\`

Stats utilisateur :
${JSON.stringify(stats, null, 2)}
`.trim()
}

// Prompt batch
function buildBatchPrompt(
  stats: any,
  objectif: string,
  count: number,
  startDate: string
): string {
  return `
Tu es un coach sportif IA.

### TA TÂCHE
Génère **EXACTEMENT un tableau JSON** contenant **${count} objets Programme**,
quotidiens consécutifs à partir du ${startDate} inclus, selon l’objectif [${objectif}].

➡️ Le résultat doit être **UNIQUEMENT** :
\`\`\`json
[ { ... }, { ... }, ..., { ... } ]
\`\`\`
Aucun texte avant ou après.

### Règles (rappel)
- Types d'exercices autorisés : Street Workout, Course, Cardio libre, Shadow Boxing, Repos actif, Plyometrie, Renfo avec charges
- Sous-types valides (un seul par exercice) : cf. tableau
- Intensités admises : "Faible", "Moderee", "Elevee"
- *restTime* en secondes, *duration* en minutes si numérique.
- Un même sous-type ne doit apparaître qu’une fois par programme.

Regles SUR LES SOUS-TYPES :
| Type                  | Sous-types autorises (exactement UNE valeur)               |
|-----------------------|------------------------------------------------------------|
| Street Workout        | Pompes • Tractions • Dips • Abdos • Squats • Fentes • Gainage • Burpees • Mountain Climbers • Planche • Superman • Jump Squats |
| Plyometrie            | Sauts sur boite • Sauts lateraux • Sauts groupes • Skaters • Burpees sautes |
| Renfo avec charges    | Developpe couche • Squat barre • Souleve de terre • Rowing haltere • Developpe militaire • Curl biceps • Extension triceps |
| Course                | Sprint • Endurance • Fractionne • Montee de cote • Descente |
| Shadow Boxing         | Classique • Avec elastiques • Avec poids • Defense / Esquives • Travail vitesse |
| Repos actif           | Marche lente • Etirements • Respiration • Mobilite • Roulements d\'epaules • Rotation de hanches |

### Exemple de réponse (plus de 5 exercices par programme sauf si repos bien sur)
\`\`\`json
[
  {
    "nom": "Programme IA – 2023-10-01",
    "date": "2023-10-01",     
    "commentaire": "Programme orienté puissance & cardio",
    "exercices": [
      {
        "type": "Street Workout",
        "subType": "Pompes",
        "series": "4",
        "duration": "",
        "repetitions": "15",
        "restTime": "60",
        "intensity": "Elevee",
        "accompli": false
      }
    ]
  },
  {
    "nom": "Programme IA – 2023-10-02",
    "date": "2023-10-02",
    "commentaire": "Programme orienté endurance",   
    "exercices": [
      {
        "type": "Course",
        "subType": "Endurance",
        "series": "",
        "duration": "30",
        "repetitions": "",
        "restTime": "120",
        "intensity": "Moderee",
        "accompli": false
      }
    ]
  }
]
\`\`\`

Stats utilisateur :
${JSON.stringify(stats, null, 2)}
`.trim()
}

// SubType validation
function getCorrectSubType(type: string, providedSubType: string): string {
  const dict: Record<string, string[]> = {
    'Street Workout': ['Pompes', 'Tractions', 'Dips', 'Abdos', 'Squats', 'Fentes', 'Gainage', 'Burpees', 'Mountain Climbers', 'Planche', 'Superman', 'Jump Squats'],
    'Plyometrie': ['Sauts sur boite', 'Sauts lateraux', 'Sauts groupes', 'Skaters', 'Burpees sautes'],
    'Renfo avec charges': ['Developpe couche', 'Squat barre', 'Souleve de terre', 'Rowing haltere', 'Developpe militaire', 'Curl biceps', 'Extension triceps'],
    'Course': ['Sprint', 'Endurance', 'Fractionne', 'Montee de cote', 'Descente'],
    'Shadow Boxing': ['Classique', 'Avec elastiques', 'Avec poids', 'Defense / Esquives', 'Travail vitesse'],
    'Cardio libre': ['Classique'],
    'Repos actif': ['Marche lente', 'Etirements', 'Respiration', 'Mobilite', 'Roulements d\'epaules', 'Rotation de hanches']
  }
  return dict[type]?.includes(providedSubType) ? providedSubType : dict[type]?.[0] ?? ''
}

// Intensity normalizer
function normalizeIntensity(i: string): 'Faible' | 'Moderee' | 'Elevee' {
  const norm = i.toLowerCase()
  if (['faible', 'low', 'basse'].includes(norm)) return 'Faible'
  if (['moderee', 'modere', 'moyenne', 'medium'].includes(norm)) return 'Moderee'
  if (['elevee', 'haute', 'forte', 'high'].includes(norm)) return 'Elevee'
  return 'Moderee'
}
function mapExercise(ex: any) {
  const t = ex.type || 'Street Workout'
  return {
    type: t,
    subType: getCorrectSubType(t, ex.subType || ''),
    series: ex.series || '1',
    distance: ex.distance || '',
    duration: ex.duration || '',
    repetitions: ex.repetitions || '',
    restTime: ex.restTime || '60',
    intensity: normalizeIntensity(ex.intensity || 'Moderee'),
    accompli: false
  }
}
export default {
  async fetch(req: Request, env: { OPENROUTER_API_KEY: string }) {
    const cors = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    }
    if (req.method === 'OPTIONS') return new Response(null, { headers: cors })
    if (req.method !== 'POST') return new Response('Use POST', { status: 405, headers: cors })

const raw = await req.json().catch(() => ({}))
const body = raw as BatchBody

if (!body.uid) return new Response('uid missing', { status: 400, headers: cors })

    const isBatch = new URL(req.url).pathname.endsWith('/generate-programs')
    const objectif = body.objectif || 'Maintenir le rythme'
    const stats = body.stats || {}

    const openai = new OpenAI({ baseURL: 'https://openrouter.ai/api/v1', apiKey: env.OPENROUTER_API_KEY })

    try {
      /* ────────── BATCH (week / month) ────────── */
      if (isBatch) {
        const totalDays = body.range === 'month' ? 30 : 7
        let remaining = totalDays
        let cursor = formatDate(body.startDate || new Date())
        let all: Program[] = []

        while (remaining > 0) {
          const count = Math.min(CHUNK, remaining)
          const prompt = buildBatchPrompt(stats, objectif, count, cursor)

          const res = await openai.chat.completions.create({
            model: MODEL,
            messages: [{ role: 'user', content: prompt }],
            temperature: 0.7,
            max_tokens: 4096
          })

          let answer = res.choices?.[0]?.message?.content ?? '[]'
          answer = answer.replace(/^```json\s*|\s*```$/g, '').trim()
          const chunk = JSON.parse(answer)
          const arr: Program[] = (Array.isArray(chunk) ? chunk : [chunk]).map((p: any) => ({
            nom: p.nom || `Programme IA – ${p.date}`,
            date: p.date,
            commentaire: p.commentaire || '',
            exercices: (p.exercices || []).map(mapExercise)
          }))

          all.push(...arr)
          remaining -= count
          cursor = addDays(cursor, count)
        }

        return new Response(JSON.stringify({ programs: all }), { headers: { 'Content-Type': 'application/json', ...cors } })
      }

      /* ────────── JOURNALIER ────────── */
      const singleBody = body as BodyIn
      const prompt = buildPrompt(stats, objectif, singleBody)
      const r = await openai.chat.completions.create({
        model: MODEL,
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.7
      })

      let answer = r.choices?.[0]?.message?.content ?? '{}'
      answer = answer.replace(/^```json\s*|\s*```$/g, '').trim()
      const p: any = JSON.parse(answer)

      const program: Program = {
        nom: `Programme IA – ${body.date || formatDate(new Date())}`,
        date: p.date,
        commentaire: p.commentaire ?? '',
        exercices: (p.exercices || []).map(mapExercise)
      }

      return new Response(JSON.stringify(program), { headers: { 'Content-Type': 'application/json', ...cors } })
    } catch (e) {
      console.error('❌ ERREUR IA :', e)
      return new Response('Erreur serveur: ' + e, { status: 500, headers: cors })
    }
  }
}