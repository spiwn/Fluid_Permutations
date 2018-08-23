RECIPE_AFFIX = "-fp"
ITEM_GROUP_NAME = "fluidpermutations"

NEXT_INGREDIENT_KEY = 1
PREVIOUS_INGREDIENT_KEY = 2
NEXT_RESULT_KEY = 3
PREVIOUS_RESULT_KEY = 4

NEXT_INGREDIENTS_PERMUTATION_INPUT = "next-ingredients-fluid-recipe"
PREVIOUS_INGREDIENTS_PERMUTATION_INPUT = "previous-ingredients-fluid-recipe"
NEXT_RESULTS_PERMUTATION_INPUT = "next-results-fluid-recipe"
PREVIOUS_RESULTS_PERMUTATION_INPUT = "previous-results-fluid-recipe"

OMNIPERMUTE_AFFIX = "-omniperm"

functions = {
    generateRecipeName = function(base, affix, difficulty, ingredientPermutation, resultPermutation, control)
        local prefix = base
        if (control == nil or control == false) and select(1, string.find(base, "omnirec")) ~= nil then
            prefix = prefix..OMNIPERMUTE_AFFIX.."-"..ingredientPermutation.."-"..resultPermutation
        end
        return prefix..affix.."-d"..difficulty.."-i"..ingredientPermutation.."-r"..resultPermutation
    end,
}
