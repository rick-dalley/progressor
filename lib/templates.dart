
// Helper for the POC to provide the "Gauge" configuration
class templates {

  static Map<String, dynamic> getGad7Template() {
    return {
      "title": "Generalized Anxiety Disorder 7 Item Scale (GAD-7)",
      "column_headers": [
        "Over the last 2 weeks, how often have you been bothered by any of the following problems?",
        "Not at all",
        "Several days",
        "More than half the days",
        "Nearly every day"],
      "questions_score": [
        {
          "id": "q1",
          "text": "1. Feeling nervous, anxious or on edge",
          "max_score": 3
        },
        {
          "id": "q2",
          "text": "2. Not being able to stop or control worrying",
          "max_score": 3
        },
        {
          "id": "q3",
          "text": "3. Worrying too much about different things?",
          "max_score": 3
        },
        {
          "id": "q4",
          "text": "4. Trouble relaxing",
          "max_score": 3
        },
        {"id": "q5", "text": "5. Being so restless that it is hard to sit still", "max_score": 3},
        {
          "id": "q6",
          "text": "6. Becoming annoyed or irritable",
          "max_score": 3
        },
        {
          "id": "q7",
          "text": "7. Feeling afrais as if something awful might happen",
          "max_score": 3
        },
      ]
    };
  }

  static Map<String, dynamic> getPhq9Template() {
    return {
      "title": "Patient Health Questionnaire (PHQ-9)",
      "column_headers": [
        "Over the last 2 weeks, how often have you been bothered by any of the following problems?",
        "Not at all",
        "Several days",
        "More than half the days",
        "Nearly every day"],
      "questions_score": [
        {
          "id": "q1",
          "text": "1. Little interest or pleasure in doing things?",
          "max_score": 3
        },
        {
          "id": "q2",
          "text": "2. Feeling down, depressed, or hopeless?",
          "max_score": 3
        },
        {
          "id": "q3",
          "text": "3. Trouble falling or staying asleep, or sleeping too much?",
          "max_score": 3
        },
        {
          "id": "q4",
          "text": "4. Feeling tired or having little energy",
          "max_score": 3
        },
        {"id": "q5", "text": "5. Poor appetite or overeating", "max_score": 3},
        {
          "id": "q6",
          "text": "6. Feeling bad about yourself - or that you are a failure to or have let yourself or your family down?",
          "max_score": 3
        },
        {
          "id": "q7",
          "text": "7. Trouble concentrating on things, such as reading the newspaper or watching television?",
          "max_score": 3
        },
        {
          "id": "q8",
          "text": "8. Moving or speaking so slowly that other people could have noticed?  Or the opposite – being so fidgety or restless that you have been moving around a lot more than usual?",
          "max_score": 3
        },
        {
          "id": "q9",
          "text": "9. Thoughts that you would be better off dead or of hurting yourself in some way?",
          "max_score": 3
        },
        // ... add the rest here
      ],
      "questions_impact_text": "If you checked off any problems, how difficult have these problems made it for you to do your work, take care of things at home, or get along with other people?",
      "questions_impact": [
        {"id": "q10", "text": "Not difficult at all", "bool": false},
        {"id": "q11", "text": "Somewhat difficult", "bool": false},
        {"id": "q12", "text": "Very difficult", "bool": false},
        {"id": "q13", "text": "Extremely difficult", "bool": false},
      ],
    };
  }
}