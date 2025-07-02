// File: src/index.ts - Fixed subType logic
import { OpenAI } from 'openai'

interface Program {
  nom: string
  date: string
  commentaire: string
  exercices: {
    type: string
    subType: string
    series: string
    distance: string // Optional for Course, Cardio libre, Shadow Boxing, Repos actif
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

const MODEL = "deepseek/deepseek-chat:free"

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
- Chaque sous-type d'un meme type ne doit apparaitre qu'une seule fois (pas de doublon « Pompes » × 2).
- Utilise UNIQUEMENT les intensites : **"Faible"**, **"Moderee"**, **"Elevee"** (sans accents).
- Toutes les durees **restTime** sont en **secondes** et **duration** **minutes** si numeriques, sinon chaine vide.
- NE RENVOIE QUE le JSON, encadre par \`\`\`json … \`\`\` – aucun texte avant/apres.

Exemple :

\`\`\`json
{
  "nom"        : "Programme IA – ${selectedDate}",
  "date"       : "${selectedDate}",
  "commentaire": "Programme oriente puissance & cardio",
  "exercices"  : [
    {
      "type"       : "Street Workout",
      "subType"    : "Pompes",
      "series"     : "4",
      "duration"   : "",
      "repetitions": "15",
      "restTime"   : "60",
      "intensity"  : "Elevee",
      "accompli"   : false
    },
    {
      "type"       : "Course",
      "subType"    : "Sprint",
      "distance"   : "5",      // km
      "series"     : "1",
      "duration"   : "1500",   // secondes
      "repetitions": "",
      "restTime"   : "",
      "intensity"  : "Moderee",
      "accompli"   : false
    }
  ]
}
\`\`\`

Stats utilisateur :
${JSON.stringify(stats, null, 2)}
`.trim()
}

// Helper function to get correct subType based on type
function getCorrectSubType(type: string, providedSubType: string): string {
  switch (type) {
    case 'Street Workout':
      // For Street Workout, return provided subType if valid, otherwise default to Pompes
      const validStreetSubTypes = [
        'Pompes', 'Tractions', 'Dips', 'Abdos', 'Squats', 'Fentes', 
        'Gainage', 'Burpees', 'Mountain Climbers', 'Planche', 'Superman', 'Jump Squats'
      ];
      return validStreetSubTypes.includes(providedSubType) ? providedSubType : 'Pompes';
    
    case 'Plyometrie':
      // For Plyometrie, return provided subType if valid
      const validPlyoSubTypes = [
        'Sauts sur boite', 'Sauts lateraux', 'Sauts groupes', 'Skaters', 'Burpees sautes'
      ];
      return validPlyoSubTypes.includes(providedSubType) ? providedSubType : 'Sauts sur boite';
    
    case 'Renfo avec charges':
      // For Renfo avec charges, return provided subType if valid
      const validRenfoSubTypes = [
        'Developpe couche', 'Squat barre', 'Souleve de terre', 'Rowing haltere', 
        'Developpe militaire', 'Curl biceps', 'Extension triceps'
      ];
      return validRenfoSubTypes.includes(providedSubType) ? providedSubType : 'Developpe couche';
    
    case 'Course':
      // For Course, return provided subType if valid
      const validCourseSubTypes = ['Sprint', 'Endurance', 'Fractionne', 'Montee de cote', 'Descente'];
      return validCourseSubTypes.includes(providedSubType) ? providedSubType : 'Sprint';
    case 'Cardio libre':
    case 'Shadow Boxing':
      // For Cardio libre and Shadow Boxing, return provided subType if valid
      const validCardioSubTypes = ['Classique', 'Avec elastiques', 'Avec poids', 'Defense / Esquives', 'Travail vitesse'];
      return validCardioSubTypes.includes(providedSubType) ? providedSubType : 'Classique';
    case 'Repos actif':
      const validReposSubTypes = ['Marche lente', 'Etirements', 'Respiration', 'Mobilite', 'Roulements d\'epaules', 'Rotation de hanches'];
      return validReposSubTypes.includes(providedSubType) ? providedSubType : 'Marche lente';

      // For these types, subType should always be empty
      return '';
    
    default:
      return '';
  }
}

// Helper function to normalize intensity values
function normalizeIntensity(intensity: string): 'Faible' | 'Moderee' | 'Elevee' {
  const normalized = intensity.toLowerCase().trim()
  
  switch (normalized) {
    case 'faible':
    case 'basse':
    case 'low':
      return 'Faible'
    case 'moderee':
    case 'modere':
    case 'moyenne':
    case 'medium':
      return 'Moderee'
    case 'elevee':
    case 'haute':
    case 'forte':
    case 'high':
      return 'Elevee'
    default:
      console.warn(`Unknown intensity: ${intensity}, defaulting to Moderee`)
      return 'Moderee'
  }
}

export default <ExportedHandler>{
  async fetch(req: Request, env: { OPENROUTER_API_KEY: string }) {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    }

    // Handle preflight requests
    if (req.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders })
    }

    // 1) Methode autorisee ?
    if (req.method !== "POST") {
      return new Response("Use POST", { status: 405, headers: corsHeaders })
    }

    // 2) Recuperation / validation du body
    let body: BodyIn
    try {
      body = (await req.json()) as BodyIn
    } catch (e) {
      console.error('Erreur parsing JSON:', e)
      return new Response("Bad JSON", { status: 400, headers: corsHeaders })
    }

    const { uid, objectif = "Maintenir le rythme", stats = {}, date } = body;
    if (!uid) {
      return new Response("uid missing", { status: 400, headers: corsHeaders })
    }

    const selectedDate = date || new Date().toISOString().split('T')[0];

    try {
      // 3) Appel OpenRouter
      const openai = new OpenAI({
        baseURL: "https://openrouter.ai/api/v1",
        apiKey: env.OPENROUTER_API_KEY,
      })

      const prompt = buildPrompt(stats, objectif, body)
      console.log('Prompt envoye:', prompt)
      
      const completion = await openai.chat.completions.create({
        model: MODEL,
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
      })

      let answer = completion.choices[0]?.message?.content?.trim() || "{}"
      console.log('Reponse IA brute:', answer)
      
      // Nettoyage de la reponse
      answer = answer.replace(/^```json\s*|\s*```$/g, "").trim()
      
      let program: Program
      try {
        program = JSON.parse(answer)
        
        // Validation du programme
        if (!program.exercices || !Array.isArray(program.exercices)) {
          throw new Error('Exercices manquants ou format invalide')
        }
        
        // Assurer que chaque exercice a les bonnes proprietes avec logique corrigee
        program.exercices = program.exercices.map(ex => {
          const exerciseType = ex.type || 'Street Workout';
          return {
            type: exerciseType,
            subType: getCorrectSubType(exerciseType, ex.subType || ''),
            series: ex.series || '1',
            duration: ex.duration || '',
            distance: ex.distance || '',
            repetitions: ex.repetitions || '',
            restTime: ex.restTime || '60',
            intensity: normalizeIntensity(ex.intensity || 'Moderee'),
            accompli: false
          };
        });
        program.nom = `Programme IA – ${selectedDate}`;
        program.date = selectedDate;  
        
        console.log('Programme valide:', JSON.stringify(program, null, 2))
        
      } catch (parseError) {
        console.error('Erreur parsing JSON IA:', parseError)
        console.error('Reponse IA apres nettoyage:', answer)
        
        // Programme de fallback
        program = {
          nom: `Programme IA – ${new Date().toISOString().split('T')[0]}`,
          date: new Date().toISOString().split('T')[0],
          commentaire: "Programme genere automatiquement suite a une erreur de parsing",
          exercices: [
            {
              type: "Street Workout",
              subType: "Pompes",
              series: "3",
              duration: "",
              distance: "",
              repetitions: "10",
              restTime: "60",
              intensity: "Moderee",
              accompli: false
            },
            {
              type: "Course",
              subType: "",
              series: "1",
              distance: "5", // en km
              duration: "1500",
              repetitions: "",
              restTime: "",
              intensity: "Faible",
              accompli: false
            }
          ]
        }
      }

      return new Response(JSON.stringify(program), {
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders
        }
      })
      
    } catch (error) {
      console.error('Erreur generale:', error)
      return new Response(`Erreur serveur: ${error}`, { 
        status: 500, 
        headers: corsHeaders 
      })
    }
  },
}