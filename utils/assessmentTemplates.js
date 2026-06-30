const childQuestions = [
  {
    id: 'child_point_follow',
    text: 'If you point at something across the room, does your child look at it?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_hearing_concern',
    text: 'Have you ever wondered if your child might be deaf?',
    options: ['Yes', 'No'],
    riskAnswer: 'Yes'
  },
  {
    id: 'child_pretend_play',
    text: 'Does your child play pretend or make-believe?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_climbing',
    text: 'Does your child like climbing on things?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_finger_movements',
    text: 'Does your child make unusual finger movements near their eyes?',
    options: ['Yes', 'No'],
    riskAnswer: 'Yes'
  },
  {
    id: 'child_point_help',
    text: 'Does your child point with one finger to ask for something or to get help?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_interaction',
    text: 'Does your child interact with other children?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_name_response',
    text: 'Does your child respond when you call their name?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_words',
    text: 'Does your child use between one and three words?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_simple_instructions',
    text: 'Does your child understand simple instructions, such as "Where is teddy?"',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_eye_contact',
    text: 'Does your child look you in the eye when you are talking to them?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_copying',
    text: 'Does your child try to copy what you do?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_joint_attention',
    text: 'If you turn your head to look at something, does your child look around to see what you are looking at?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_understands_requests',
    text: 'Does your child understand when you tell them to do something?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  }
];

const adultQuestions = [
  {
    id: 'adult_prefer_alone',
    text: 'I often prefer to do things on my own rather than with others.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_same_way',
    text: 'I prefer doing things the same way, such as following a familiar routine.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_absorbed',
    text: 'I become strongly absorbed in specific interests or activities.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_noise_sensitive',
    text: 'I am very sensitive to sounds, textures, lights, or crowded environments.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_politeness_mismatch',
    text: 'People sometimes say I seem rude even when I think I am being polite.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_group_talk',
    text: 'I find it easy to talk in groups of people.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Slightly Disagree', 'Definitely Disagree']
  },
  {
    id: 'adult_things_people',
    text: 'I am more interested in finding out about things than people.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_info_patterns',
    text: 'I find numbers, dates, patterns, or strings of information fascinating.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_routine_change',
    text: 'I find it upsetting when my daily routine is changed unexpectedly.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_body_language',
    text: 'It is difficult for me to understand other people\'s facial expressions or body language.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  }
];

const templates = {
  child: {
    id: 'child-developmental-screener-v1',
    type: 'child',
    title: 'Child developmental screening support',
    version: 1,
    disclaimer: 'This screening summary is not a medical diagnosis. It is only a support tool for organizing concerns and deciding whether professional advice may be useful.',
    questions: childQuestions
  },
  adult: {
    id: 'adult-self-check-v1',
    type: 'adult',
    title: 'Adult autism-related self-check',
    version: 1,
    disclaimer: 'This self-check is not a medical diagnosis. It can help organize concerns before speaking with a qualified professional.',
    questions: adultQuestions
  }
};

function getTemplate(type) {
  return templates[type] || null;
}

function publicTemplate(template) {
  return {
    id: template.id,
    type: template.type,
    title: template.title,
    version: template.version,
    disclaimer: template.disclaimer,
    questions: template.questions.map(question => ({
      id: question.id,
      text: question.text,
      options: question.options
    }))
  };
}

function calculateResult(type, responses) {
  const template = getTemplate(type);

  if (!template) {
    throw new Error('Unknown assessment type.');
  }

  const responseMap = new Map(
    responses.map(response => [String(response.questionId || ''), String(response.answer || '')])
  );

  const scoredResponses = template.questions.map(question => {
    const answer = responseMap.get(question.id) || '';
    const riskAnswers = question.riskAnswers || [question.riskAnswer];
    const isRisk = riskAnswers.includes(answer);

    return {
      questionId: question.id,
      question: question.text,
      answer,
      score: isRisk ? 1 : 0
    };
  });

  const unanswered = scoredResponses.filter(response => !response.answer);
  if (unanswered.length > 0) {
    throw new Error('Please answer all screening questions before submitting.');
  }

  const score = scoredResponses.reduce((total, response) => total + response.score, 0);
  const maxScore = template.questions.length;

  let band = 'low';
  let recommendation = 'Low likelihood indicators. Continue regular monitoring and use professional advice if concerns continue.';

  if (type === 'child') {
    if (score >= 6) {
      band = 'high';
      recommendation = 'High likelihood indicators. A professional developmental evaluation is recommended.';
    } else if (score >= 3) {
      band = 'moderate';
      recommendation = 'Moderate likelihood indicators. Follow-up questions or consultation with a qualified professional is recommended.';
    }
  } else {
    if (score >= 7) {
      band = 'high';
      recommendation = 'High likelihood indicators. Consider a professional autism assessment or referral.';
    } else if (score >= 4) {
      band = 'moderate';
      recommendation = 'Moderate likelihood indicators. Follow-up with a qualified professional may be useful.';
    }
  }

  return {
    template,
    score,
    maxScore,
    band,
    recommendation,
    responses: scoredResponses
  };
}

module.exports = {
  templates,
  getTemplate,
  publicTemplate,
  calculateResult
};
