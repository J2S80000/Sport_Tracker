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
    duration: string
    repetitions: string
    restTime: string
    intensity: 'Faible' | 'Modérée' | 'Élevée'
    accompli: boolean
  }[]
}

interface BodyIn {
  uid: string
  objectif?: string
  stats?: any
}

const MODEL = "deepseek/deepseek-chat:free"

function buildPrompt(stats: any, objectif: string) {
  const today = new Date().toISOString().split('T')[0]
  return `
Tu es un coach sportif IA. En t'appuyant sur les statistiques JSON suivantes et l'objectif [${objectif}], 
Génère un programme au **format JSON strict**. 

Utilise uniquement les types suivants : Street Workout, Course, Cardio libre, Shadow Boxing, Repos actif.

IMPORTANT pour les sous-types :
- Street Workout : OBLIGATOIRE, choisis UN seul parmi : Pompes, Tractions, Dips, Abdos (chacun ne doit apparaître qu'une fois max)
- Course, Cardio libre, Shadow Boxing, Repos actif : subType doit être une chaîne VIDE ""

IMPORTANT pour l'intensité : utilise UNIQUEMENT "Faible", "Modérée", "Élevée" (avec accents).

NE RENVOIE QUE le contenu JSON dans une balise \`\`\`json. Aucun texte avant ou après.

Exemple de structure :
{
  "nom": "Programme IA – ${today}",
  "date": "${today}",
  "commentaire": "<texte explicatif du programme>",
  "exercices": [
    {
      "type": "Street Workout",
      "subType": "Pompes",
      "series": "4",
      "duration": "",
      "repetitions": "12",
      "restTime": "60s",
      "intensity": "Modérée",
      "accompli": false
    },
    {
      "type": "Course",
      "subType": "",
      "series": "1",
      "duration": "2000", // en secondes
      "repetitions": "",
      "restTime": "",
      "intensity": "Faible",
      "accompli": false
    }
  ]
}

Stats utilisateur:
${JSON.stringify(stats, null, 2)}
`.trim()
}

// Helper function to get correct subType based on type
function getCorrectSubType(type: string, providedSubType: string): string {
  switch (type) {
    case 'Street Workout':
      // For Street Workout, return provided subType if valid, otherwise default to Pompes
      const validSubTypes = ['Pompes', 'Tractions', 'Dips', 'Abdos'];
      return validSubTypes.includes(providedSubType) ? providedSubType : 'Pompes';
    
    case 'Course':
    case 'Cardio libre':
    case 'Shadow Boxing':
    case 'Repos actif':
      // For these types, subType should always be empty
      return '';
    
    default:
      return '';
  }
}

// Helper function to normalize intensity values
function normalizeIntensity(intensity: string): 'Faible' | 'Modérée' | 'Élevée' {
  const normalized = intensity.toLowerCase().trim()
  
  switch (normalized) {
    case 'faible':
    case 'basse':
    case 'low':
      return 'Faible'
    case 'modérée':
    case 'moderee':
    case 'moyenne':
    case 'medium':
    case 'modéré':
      return 'Modérée'
    case 'élevée':
    case 'elevee':
    case 'haute':
    case 'forte':
    case 'high':
      return 'Élevée'
    default:
      console.warn(`Unknown intensity: ${intensity}, defaulting to Modérée`)
      return 'Modérée'
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

    // 1) Méthode autorisée ?
    if (req.method !== "POST") {
      return new Response("Use POST", { status: 405, headers: corsHeaders })
    }

    // 2) Récupération / validation du body
    let body: BodyIn
    try {
      body = (await req.json()) as BodyIn
    } catch (e) {
      console.error('Erreur parsing JSON:', e)
      return new Response("Bad JSON", { status: 400, headers: corsHeaders })
    }

    const { uid, objectif = "Maintenir le rythme", stats = {} } = body
    if (!uid) {
      return new Response("uid missing", { status: 400, headers: corsHeaders })
    }

    try {
      // 3) Appel OpenRouter
      const openai = new OpenAI({
        baseURL: "https://openrouter.ai/api/v1",
        apiKey: env.OPENROUTER_API_KEY,
      })

      const prompt = buildPrompt(stats, objectif)
      console.log('Prompt envoyé:', prompt)
      
      const completion = await openai.chat.completions.create({
        model: MODEL,
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
      })

      let answer = completion.choices[0]?.message?.content?.trim() || "{}"
      console.log('Réponse IA brute:', answer)
      
      // Nettoyage de la réponse
      answer = answer.replace(/^```json\s*|\s*```$/g, "").trim()
      
      let program: Program
      try {
        program = JSON.parse(answer)
        
        // Validation du programme
        if (!program.exercices || !Array.isArray(program.exercices)) {
          throw new Error('Exercices manquants ou format invalide')
        }
        
        // Assurer que chaque exercice a les bonnes propriétés avec logique corrigée
        program.exercices = program.exercices.map(ex => {
          const exerciseType = ex.type || 'Street Workout';
          return {
            type: exerciseType,
            subType: getCorrectSubType(exerciseType, ex.subType || ''), // 👈 Fixed logic
            series: ex.series || '1',
            duration: ex.duration || '',
            repetitions: ex.repetitions || '',
            restTime: ex.restTime || '60',
            intensity: normalizeIntensity(ex.intensity || 'Modérée'),
            accompli: false
          };
        });
        
        console.log('Programme validé:', JSON.stringify(program, null, 2))
        
      } catch (parseError) {
        console.error('Erreur parsing JSON IA:', parseError)
        console.error('Réponse IA après nettoyage:', answer)
        
        // Programme de fallback
        program = {
          nom: `Programme IA – ${new Date().toISOString().split('T')[0]}`,
          date: new Date().toISOString().split('T')[0],
          commentaire: "Programme généré automatiquement suite à une erreur de parsing",
          exercices: [
            {
              type: "Street Workout",
              subType: "Pompes",
              series: "3",
              duration: "",
              repetitions: "10",
              restTime: "60",
              intensity: "Modérée",
              accompli: false
            },
            {
              type: "Course",
              subType: "", // 👈 Empty for Course
              series: "1",
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
      console.error('Erreur générale:', error)
      return new Response(`Erreur serveur: ${error}`, { 
        status: 500, 
        headers: corsHeaders 
      })
    }
  },
}