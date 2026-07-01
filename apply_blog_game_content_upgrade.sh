#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
if [ ! -d "$ROOT/client/src" ]; then
  echo "Run this from the project root, for example: cd ~/Downloads/autismo-revamp-starter"
  exit 1
fi

mkdir -p "$ROOT/client/src/components/Blog"

cat > "$ROOT/client/src/components/Blog/blog.js" <<'BLOGJS'
import React, { useState } from "react";
import "./blog.css";

const resources = [
  {
    title: "What is autism spectrum disorder?",
    tag: "Basics",
    summary:
      "Autism is a neurodevelopmental difference that can affect communication, social interaction, sensory processing, routines, and learning patterns. Every autistic person is different, so support should be based on individual strengths and needs.",
    points: [
      "Autism is not the same for every person.",
      "Early support can help with communication, routines, and confidence.",
      "Screening tools can guide next steps, but they do not replace professional diagnosis."
    ]
  },
  {
    title: "Early signs caregivers can observe",
    tag: "Caregiver guide",
    summary:
      "Caregivers may notice differences in response to name, eye contact, pretend play, gestures, language development, sensory reactions, or repetitive behaviours. These signs are only indicators and should be reviewed with a qualified professional.",
    points: [
      "Observe patterns across different settings, not just one incident.",
      "Write down examples, dates, and situations where concerns appear.",
      "Discuss concerns with a pediatrician, psychologist, or developmental specialist."
    ]
  },
  {
    title: "How to use screening results safely",
    tag: "Screening",
    summary:
      "A screening score shows whether further evaluation may be helpful. It should never be treated as a final label. The best use of screening is to prepare better questions and observations for a professional appointment.",
    points: [
      "Low likelihood does not mean concerns should be ignored.",
      "Moderate or high likelihood means follow-up is recommended.",
      "Use reports as a conversation starter with professionals."
    ]
  },
  {
    title: "Emotion learning activities",
    tag: "Skill practice",
    summary:
      "Emotion-learning activities can help children practice identifying expressions, voice tone, and social situations. The goal is supportive practice, not forcing eye contact or changing personality.",
    points: [
      "Use short, positive sessions.",
      "Give hints and celebrate effort, not just correct answers.",
      "Repeat concepts using pictures, voice tone, stories, and real-life examples."
    ]
  },
  {
    title: "Sensory overload and calming strategies",
    tag: "Wellbeing",
    summary:
      "Some children may feel overwhelmed by sound, light, touch, crowds, clothing textures, or sudden changes. A wellbeing log can help identify triggers and strategies that actually work.",
    points: [
      "Track sleep, mood, sensory overload, and distress episodes.",
      "Note possible triggers like noise, transitions, or crowded spaces.",
      "Record strategies such as quiet breaks, visual schedules, headphones, or predictable routines."
    ]
  },
  {
    title: "Preparing for a professional evaluation",
    tag: "Next steps",
    summary:
      "A professional evaluation usually considers developmental history, caregiver observations, behaviour across settings, and standardized tools. Bringing organized notes can make the appointment more useful.",
    points: [
      "Carry screening summaries, wellbeing logs, and examples of concerns.",
      "Mention strengths, interests, communication style, and support needs.",
      "Ask what interventions, school supports, or therapy options may help."
    ]
  }
];

function Blog() {
  const [openIndex, setOpenIndex] = useState(0);

  return (
    <main className="resourcePage">
      <section className="resourceHero">
        <p className="eyebrow">Caregiver resource library</p>
        <h1>Learn, observe, and support with care.</h1>
        <p>
          Short, practical guides for understanding autism-related concerns, using screening results safely,
          supporting emotion learning, and preparing better reports for professional review.
        </p>
      </section>

      <section className="resourceNotice">
        <strong>Important:</strong> This content is for education and support only. It does not provide a medical diagnosis.
        Screening results and behaviour summaries should be reviewed with a qualified professional.
      </section>

      <section className="resourceGrid">
        {resources.map((resource, index) => {
          const isOpen = openIndex === index;
          return (
            <article className={`resourceCard ${isOpen ? "resourceCardOpen" : ""}`} key={resource.title}>
              <button className="resourceCardHeader" onClick={() => setOpenIndex(isOpen ? -1 : index)}>
                <span className="resourceTag">{resource.tag}</span>
                <h2>{resource.title}</h2>
                <span className="resourceToggle">{isOpen ? "Close" : "Read"}</span>
              </button>

              {isOpen && (
                <div className="resourceCardBody">
                  <p>{resource.summary}</p>
                  <ul>
                    {resource.points.map((point) => (
                      <li key={point}>{point}</li>
                    ))}
                  </ul>
                </div>
              )}
            </article>
          );
        })}
      </section>
    </main>
  );
}

export default Blog;
BLOGJS

cat > "$ROOT/client/src/components/Blog/blog.css" <<'BLOGCSS'
.resourcePage {
  min-height: calc(100vh - 56px);
  padding: 96px 24px 56px;
  background: #1f2732;
  color: #f8fafc;
}

.resourceHero,
.resourceGrid,
.resourceNotice {
  width: min(1100px, 100%);
  margin: 0 auto;
}

.resourceHero {
  margin-bottom: 24px;
}

.eyebrow {
  margin: 0 0 10px;
  color: #b6d8d2;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  font-size: 0.82rem;
}

.resourceHero h1 {
  margin: 0;
  font-size: clamp(2rem, 5vw, 4rem);
  line-height: 1.05;
}

.resourceHero p {
  max-width: 780px;
  margin: 18px 0 0;
  color: #dbe7e4;
  font-size: 1.05rem;
  line-height: 1.7;
}

.resourceNotice {
  padding: 18px 20px;
  margin-bottom: 24px;
  border: 1px solid rgba(182, 216, 210, 0.45);
  border-radius: 18px;
  background: rgba(182, 216, 210, 0.12);
  color: #edf7f5;
  line-height: 1.6;
}

.resourceGrid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 18px;
}

.resourceCard {
  overflow: hidden;
  border-radius: 20px;
  background: #ffffff;
  color: #12333a;
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.18);
}

.resourceCardOpen {
  grid-row: span 2;
}

.resourceCardHeader {
  width: 100%;
  text-align: left;
  border: 0;
  background: transparent;
  padding: 22px;
  cursor: pointer;
  color: inherit;
}

.resourceTag {
  display: inline-block;
  margin-bottom: 12px;
  padding: 6px 10px;
  border-radius: 999px;
  background: #d8efeb;
  color: #155e59;
  font-weight: 800;
  font-size: 0.78rem;
}

.resourceCard h2 {
  margin: 0;
  font-size: 1.35rem;
  line-height: 1.25;
}

.resourceToggle {
  display: inline-block;
  margin-top: 16px;
  font-weight: 800;
  color: #176b64;
}

.resourceCardBody {
  padding: 0 22px 22px;
  color: #334155;
  line-height: 1.65;
}

.resourceCardBody p {
  margin: 0 0 12px;
}

.resourceCardBody ul {
  margin: 0;
  padding-left: 20px;
}

.resourceCardBody li {
  margin: 8px 0;
}

@media (max-width: 800px) {
  .resourcePage {
    padding: 84px 16px 40px;
  }

  .resourceGrid {
    grid-template-columns: 1fr;
  }

  .resourceCardOpen {
    grid-row: auto;
  }
}
BLOGCSS

cat > "$ROOT/client/src/components/LevelScreen/LevelScreen.js" <<'LEVELJS'
import React, { Component } from "react";
import { Link } from "react-router-dom";
import FooterSection from "../FooterSection/FooterSection";
import classes from "./LevelScreen.module.css";

const gameModes = [
  {
    to: "/level1",
    label: "Expression Match",
    level: "Level 1",
    description: "Practice identifying emotions from friendly face illustrations.",
    icon: "😊"
  },
  {
    to: "/level2",
    label: "Voice Tone Cues",
    level: "Level 2",
    description: "Listen to short voice tones and choose the emotion they suggest.",
    icon: "🎧"
  },
  {
    to: "/level3",
    label: "Social Story Cues",
    level: "Level 3",
    description: "Read simple social situations and pick the most likely feeling.",
    icon: "💬"
  }
];

class LevelScreen extends Component {
  render() {
    return (
      <div className="App" style={{ minHeight: "100%" }}>
        <main className={classes.PageContent}>
          <section className={classes.GameHero}>
            <p className={classes.Eyebrow}>Emotion learning games</p>
            <h1>Choose a practice mode</h1>
            <p>
              Build emotion-recognition skills through short, supportive activities using expressions,
              voice tone, and social-story cues.
            </p>
          </section>

          <section className={classes.ModeGrid}>
            {gameModes.map((mode) => (
              <Link className={classes.ModeCard} to={mode.to} key={mode.to}>
                <div className={classes.ModeIcon}>{mode.icon}</div>
                <span>{mode.level}</span>
                <h2>{mode.label}</h2>
                <p>{mode.description}</p>
                <strong>Start practice</strong>
              </Link>
            ))}
          </section>
        </main>
        <FooterSection />
      </div>
    );
  }
}

export default LevelScreen;
LEVELJS

cat > "$ROOT/client/src/components/LevelScreen/LevelScreen.module.css" <<'LEVELCSS'
.PageContent {
  min-height: calc(100vh - 56px);
  padding: 96px 24px 56px;
  background: #1f2732;
  color: #f8fafc;
}

.GameHero,
.ModeGrid {
  width: min(1100px, 100%);
  margin: 0 auto;
}

.GameHero {
  margin-bottom: 28px;
}

.Eyebrow {
  margin: 0 0 10px;
  color: #b6d8d2;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  font-size: 0.82rem;
}

.GameHero h1 {
  margin: 0;
  font-size: clamp(2.2rem, 5vw, 4.5rem);
  line-height: 1.05;
}

.GameHero p {
  max-width: 760px;
  margin: 18px 0 0;
  color: #dbe7e4;
  font-size: 1.05rem;
  line-height: 1.7;
}

.ModeGrid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
}

.ModeCard {
  display: flex;
  flex-direction: column;
  min-height: 310px;
  padding: 26px;
  border-radius: 24px;
  background: #ffffff;
  color: #12333a;
  text-decoration: none;
  box-shadow: 0 16px 44px rgba(0, 0, 0, 0.18);
  transition: transform 160ms ease, box-shadow 160ms ease;
}

.ModeCard:hover,
.ModeCard:focus {
  transform: translateY(-4px);
  box-shadow: 0 22px 60px rgba(0, 0, 0, 0.24);
  outline: none;
}

.ModeIcon {
  width: 76px;
  height: 76px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 24px;
  background: #d8efeb;
  font-size: 2.4rem;
  margin-bottom: 20px;
}

.ModeCard span {
  color: #176b64;
  font-weight: 900;
  text-transform: uppercase;
  font-size: 0.78rem;
  letter-spacing: 0.08em;
}

.ModeCard h2 {
  margin: 10px 0 10px;
  font-size: 1.55rem;
  line-height: 1.2;
}

.ModeCard p {
  margin: 0;
  color: #475569;
  line-height: 1.6;
}

.ModeCard strong {
  margin-top: auto;
  color: #0f5f59;
}

@media (max-width: 900px) {
  .ModeGrid {
    grid-template-columns: 1fr;
  }

  .ModeCard {
    min-height: auto;
  }
}

@media (max-width: 600px) {
  .PageContent {
    padding: 84px 16px 40px;
  }
}
LEVELCSS

python - <<'PY'
from pathlib import Path
root = Path.cwd()
replacements = {
    "client/src/components/Navigation/NavigationItems/NavigationItems.js": [
        (">Quiz<", ">Games<"),
        (">Blog<", ">Resources<"),
    ],
    "client/src/components/Navigation/SideDrawer/SideDrawer.js": [
        (">Quiz<", ">Games<"),
        (">Blog<", ">Resources<"),
        (">Camera<", ">Live Observation<"),
    ],
    "client/src/components/Question/Question.js": [
        ("Audio", "Voice Tone"),
        ("Videos", "Social Stories"),
        ("Video", "Social Story"),
    ],
    "client/src/components/QuizScreen/QuizScreen.js": [
        ("Audio", "Voice Tone"),
        ("Videos", "Social Stories"),
        ("Video", "Social Story"),
    ],
}
for rel, pairs in replacements.items():
    path = root / rel
    if not path.exists():
        continue
    text = path.read_text(encoding="utf-8")
    original = text
    for old, new in pairs:
        text = text.replace(old, new)
    if text != original:
        path.write_text(text, encoding="utf-8")

# Optional: update document title if present
index_html = root / "client/public/index.html"
if index_html.exists():
    text = index_html.read_text(encoding="utf-8")
    text = text.replace("AUTISMO", "AUTIASSIST").replace("Autemo", "AutiAssist")
    index_html.write_text(text, encoding="utf-8")
PY

echo "Blog/resources and game mode wording updated. Restart the React app if it does not refresh automatically."
