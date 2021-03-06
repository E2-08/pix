import _ from 'pix-live/utils/lodash-custom';

import refQcmAnswer from '../data/answers/ref-qcm-answer';
import refQcuAnswer from '../data/answers/ref-qcu-answer';
import refQrocAnswer from '../data/answers/ref-qroc-answer';
import refQrocmAnswer from '../data/answers/ref-qrocm-answer';
import refTimedAnswer from '../data/answers/ref-timed-answer';
import refTimedAnswerBis from '../data/answers/ref-timed-answer-bis';

export default function(schema, request) {

  const assessmentId = request.queryParams.assessment;
  const challengeId = request.queryParams.challenge;

  const allAnswers = [
    refQcuAnswer,
    refQcmAnswer,
    refQrocAnswer,
    refQrocmAnswer,
    refTimedAnswer,
    refTimedAnswerBis
  ];

  const answers = _.map(allAnswers, function(oneAnswer) {
    return { id: oneAnswer.data.id, obj: oneAnswer };
  });

  const answer = _.find(answers, (oneAnswer) => {
    const belongsToAssessment = _.get(oneAnswer.obj, 'data.relationships.assessment.data.id') === assessmentId;
    const belongsToChallenge = _.get(oneAnswer.obj, 'data.relationships.challenge.data.id') === challengeId;
    return belongsToAssessment && belongsToChallenge;
  });

  if (answer) {
    return answer.obj;
  }

  // XXX schema.answers.first() (or where(), or findBy()) should return JSONAPI
  // For unknown reasons, it is not the case here (even if there is no answers found)
  // We return this valid JSON API to be sure
  const validJSONAPI = {
    data : {
      type : 'answers',
      id : 'answerId',
      attributes : {
        value : ''
      }
    }
  };

  // TODO make it work for real (use schema.answers.where({assessmentId, challengeId})
  return schema.answers.first() || validJSONAPI;
}
