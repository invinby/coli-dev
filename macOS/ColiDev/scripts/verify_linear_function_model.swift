import Foundation

@main
enum LinearFunctionModelVerification {
    static func main() {
        let function = LinearFunctionModel(slope: 2, intercept: -1)!
        precondition(close(function.value(at: 3)!, 5), "Evaluate y = 2x - 1 at x = 3. / Вычислить y = 2x - 1 при x = 3.")
        precondition(close(function.value(at: 0)!, -1), "Use the intercept as the output at x = 0. / Использовать b как значение при x = 0.")

        let descending = LinearFunctionModel(slope: -1, intercept: 4)!
        precondition(close(descending.value(at: 3)!, 1), "Evaluate a decreasing line. / Вычислить значение убывающей прямой.")
        let constant = LinearFunctionModel(slope: 0, intercept: 2)!
        precondition(close(constant.value(at: -3)!, 2), "Keep the output constant when the slope is zero. / Сохранять постоянный выход при нулевом наклоне.")

        precondition(LinearFunctionModel(slope: .infinity, intercept: 1) == nil, "Reject a non-finite slope. / Отклонить бесконечный наклон.")
        precondition(LinearFunctionModel(slope: 1, intercept: .nan) == nil, "Reject a non-finite intercept. / Отклонить нечисловой intercept.")
        precondition(function.value(at: .infinity) == nil, "Reject a non-finite input. / Отклонить бесконечный вход.")

        precondition(
            LinearFunctionPracticeRoute.matches(subjectID: "mathematics", resource: "functions_as_models"),
            "Route the Functions as Models lesson to its matching practice. / Направлять урок «Функции как модели» в соответствующий тренажёр."
        )
        precondition(
            !LinearFunctionPracticeRoute.matches(subjectID: "physics", resource: "functions_as_models")
                && !LinearFunctionPracticeRoute.matches(subjectID: "mathematics", resource: nil),
            "Do not route unrelated or missing resources to the function trainer. / Не направлять в тренажёр функции несвязанные или пустые ресурсы."
        )

        var round = LinearFunctionPredictionRound(function: function, input: 3)
        precondition(round.submit(answer: 4) == false, "Record an incorrect prediction. / Записать неверный прогноз.")
        let firstEvidence = round.evidence!
        precondition(firstEvidence.itemID == LinearFunctionPredictionRound.itemID, "Attach evidence to the functions-as-models skill. / Привязать свидетельство к навыку работы с функциями.")
        precondition(firstEvidence.attempts == 1 && !firstEvidence.firstTryCorrect, "Record incorrect first-try evidence. / Сохранить неверный первый ответ.")
        precondition(round.submit(answer: 5) == nil, "Require an explicit retry after feedback. / Требовать явного повтора после обратной связи.")
        round.retry()
        precondition(round.submit(answer: 5) == true, "Accept the corrected prediction. / Принять исправленный прогноз.")
        let retryEvidence = round.evidence!
        precondition(retryEvidence.attempts == 2 && !retryEvidence.firstTryCorrect, "Preserve first-try correctness after a successful retry. / Сохранить оценку первой попытки после верного повтора.")

        var correctFirstTry = LinearFunctionPredictionRound(function: function, input: 3)
        precondition(correctFirstTry.submit(answer: 5) == true, "Accept a correct first prediction. / Принять верный прогноз с первой попытки.")
        precondition(correctFirstTry.evidence?.firstTryCorrect == true, "Record a correct first try. / Записать верный первый ответ.")

        var invalidGuess = LinearFunctionPredictionRound(function: function, input: 3)
        precondition(invalidGuess.submit(answer: .infinity) == nil && invalidGuess.evidence == nil, "Do not record non-finite answers. / Не записывать бесконечные ответы.")

        print("Linear function model checks passed. / Проверки линейной функции прошли.")
    }

    private static func close(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 1e-9
    }
}
