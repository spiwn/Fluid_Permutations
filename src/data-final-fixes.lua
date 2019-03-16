require("common")

local permutationsThreshold = settings.startup["fluid-permutations-threshold"].value

local function factorial(num)
    local result = 1
    for i = 2, num do
        result = result * i
    end
    return result
end

local function fluidCount(items)
    if items == nil then
        return 0
    end
    local count = 0
    for i = 1, #items do
        if items[i] ~= nil and items[i].type == "fluid" then
            count = count + 1
        end
    end
    return count
end

local function separateFluids(items)
    local fluids = {}
    local solids = {}
    for _, i in pairs(items) do
        if i ~= nil then
            if i.type == "fluid" then
                fluids[#fluids + 1] = i
            else
                solids[#solids + 1] = i
            end
        end
    end
    return fluids, solids
end

local function permutations(ttable, n, out)
    if n == 0 then
        out[#out + 1] = table.deepcopy(ttable)
        return
    end

    for i = 1, n do
        ttable[n], ttable[i] = ttable[i], ttable[n]
        permutations(ttable, n - 1, out)
        ttable[n], ttable[i] = ttable[i], ttable[n]
    end
end

local function concatTables(t1, t2)
    local result = {}
    for i = 1, #t1 do
        if type(t1[i]) == "table" then
            result[#result + 1] = table.deepcopy(t1[i])
        else
            result[#result + 1] = t1[i]
        end
    end
    for i = 1, #t2 do
        if type(t2[i]) == "table" then
            result[#result + 1] = table.deepcopy(t2[i])
        else
            result[#result + 1] = t2[i]
        end
    end
    return result
end

local function getFluidPermutations(tableOfItems)
    local fluids, solids = separateFluids(tableOfItems)
    local fluidPermutations = {}
    permutations(fluids, #fluids, fluidPermutations)

    local result = {}

    for i = 1, #fluidPermutations do
        local temp = concatTables(fluidPermutations[i], solids)
        result[#result + 1] = temp
    end
    return result;
end

local function checkSameItems(tab1, tab2)
    if #tab1 ~= #tab2 then
        return false
    end

    for i = 1, #tab1 do
        if tab1[i].name ~= tab2[i].name then
            return false
        end
        if tab1[i].type ~= tab2[i].type then
            return false
        end
    end
    return true
end

local accessors = {
    ingredientsSetter = function(t, difficulty, ingredients)
        t.ingredients = ingredients
    end,
    difficultyIngredientsSetter = function(t, difficulty, ingredients)
        if difficulty == "a" then
            t.normal.ingredients = ingredients["n"]
            t.expensive.ingredients = ingredients["e"]
        elseif difficulty == "n" then
            t.normal.ingredients = ingredients
        elseif difficulty == "e" then
            t.expensive.ingredients = ingredients
        end
    end,
    resultsSetter = function(t, difficulty, results)
        t.results = results
    end,
    difficultyResultsSetter = function(t, difficulty, results)
        if difficulty == "a" then
            t.normal.results = results["n"]
            t.expensive.results = results["e"]
        elseif difficulty == "n" then
            t.normal.results = results
        elseif difficulty == "e" then
            t.expensive.results = results
        end
    end
}

local function inspectRecipe(recipe)
    local permutations = {a = {}, n = {}, e = {}}
    local ingredientsSetter, resultsSetter
    local difficultyTags
    if recipe.normal then
        local normalIngredientsPermutations
        local expensiveIngredientsPermutations
        local normalResultsPermutations
        local expensiveResultsPermutations

        local permutationCount = 1

        local normalSameAsExpensive = false
        if recipe.expensive then
            normalSameAsExpensive = true

            normalSameAsExpensive = normalSameAsExpensive
                and ((recipe.normal.ingredients == nil and recipe.expensive.ingredients == nil)
                        or checkSameItems(recipe.normal.ingredients, recipe.expensive.ingredients))

            normalSameAsExpensive = normalSameAsExpensive
                and ((recipe.normal.results == nil and recipe.expensive.results == nil)
                        or (recipe.normal.results ~= nil and recipe.expensive.results ~= nil
                                and checkSameItems(recipe.normal.results, recipe.expensive.results)))

            if normalSameAsExpensive then
                difficultyTags = {"a"}
            else
                difficultyTags = {"n", "e"}
            end

            local expensiveIngredientsFluidCount = fluidCount(recipe.expensive.ingredients)
            local expensiveResultsFluidCount = fluidCount(recipe.expensive.results)
            permutationCount = math.max(1, factorial(expensiveIngredientsFluidCount)) * math.max(1, factorial(expensiveResultsFluidCount))
            if permutationCount > permutationsThreshold then
                return {}, nil, nil, {}
            end

            if expensiveIngredientsFluidCount > 1 then
                expensiveIngredientsPermutations = getFluidPermutations(recipe.expensive.ingredients)
            end
            if expensiveResultsFluidCount > 1 then
                expensiveResultsPermutations = getFluidPermutations(recipe.expensive.results)
            end
        else
            difficultyTags = {"n"}
        end

        local normalIngredientsFluidCount = fluidCount(recipe.normal.ingredients)
        local normalResultsFluidCount = fluidCount(recipe.normal.results)
        if not normalSameAsExpensive then
            permutationCount = permutationCount + factorial(normalIngredientsFluidCount) * factorial(normalResultsFluidCount)
            if permutationCount > permutationsThreshold then
                return {}, nil, nil, {}
            end
        end

        if normalIngredientsFluidCount > 1 then
            normalIngredientsPermutations = getFluidPermutations(recipe.normal.ingredients)
            ingredientsSetter = accessors.difficultyIngredientsSetter
        end
        if normalResultsFluidCount > 1 then
            normalResultsPermutations = getFluidPermutations(recipe.normal.results)
            resultsSetter = accessors.difficultyResultsSetter
        end
        if normalIngredientsPermutations and expensiveIngredientsPermutations then
            if normalSameAsExpensive then
                local combinedIngredientsPermutations = {}
                for i = 1, #normalIngredientsPermutations do
                    combinedIngredientsPermutations[#combinedIngredientsPermutations + 1] = {
                        n = normalIngredientsPermutations[i],
                        e = expensiveIngredientsPermutations[i]
                    }
                end
                permutations["a"].ingredients = combinedIngredientsPermutations
            else
                permutations["n"].ingredients = normalIngredientsPermutations
                permutations["e"].ingredients = expensiveIngredientsPermutations
            end
        elseif normalIngredientsPermutations then
            permutations["n"].ingredients = normalIngredientsPermutations
        elseif expensiveIngredientsPermutations then
            permutations["e"].ingredients = expensiveIngredientsPermutations
        end
        if normalResultsPermutations and expensiveResultsPermutations then
            if normalSameAsExpensive then
                local combinedResultPermutations = {}
                for i = 1, #normalResultsPermutations do
                    combinedResultPermutations[#combinedResultPermutations + 1] = {
                        n = normalResultsPermutations[i],
                        e = expensiveResultsPermutations[i]
                    }
                end
                permutations["a"].results = combinedResultPermutations
            else
                permutations["n"].results = normalResultsPermutations
                permutations["e"].results = expensiveResultsPermutations
            end
        elseif normalResultsPermutations then
            permutations["n"].results = normalResultsPermutations
        elseif expensiveResultsPermutations then
            permutations["e"].results = expensiveResultsPermutations
        end
    else
        local ingredientsFluidCount = fluidCount(recipe.ingredients)
        local resultsFluidCount = fluidCount(recipe.results)
        local permutationCount = factorial(ingredientsFluidCount) * factorial(resultsFluidCount)

        if permutationCount > permutationsThreshold then
            return {}, nil, nil, {}
        end

        difficultyTags = {"a"}
        if ingredientsFluidCount > 1 then
            permutations["a"].ingredients = getFluidPermutations(recipe.ingredients)
            ingredientsSetter = accessors.ingredientsSetter
        end

        if resultsFluidCount > 1 then
            permutations["a"].results = getFluidPermutations(recipe.results)
            resultsSetter = accessors.resultsSetter
        end
    end
    return permutations, ingredientsSetter, resultsSetter, difficultyTags
end

local function generateRecipePermutations(recipe)
    local permutations, ingredientsSetter, resultsSetter, difficultyTags = inspectRecipe(recipe)
    local newRecipies = {}
    for _, difficultyTag in pairs(difficultyTags) do
        local ingredientsPermutations = permutations[difficultyTag].ingredients
        local resultsPermutations = permutations[difficultyTag].results
        local maxI = 0
        local maxJ = 0
        local minI = 0
        local minJ = 0
        if ingredientsPermutations then
            maxI = #ingredientsPermutations
            minI = 1
        end
        if resultsPermutations then
            maxJ = #resultsPermutations
            minJ = 1
        end
        for i = minI, maxI do -- for difficulty
            for j = minJ, maxJ do -- for difficulty
                if i < maxI or j < maxJ then
                    local newRecipe = table.deepcopy(recipe)
                    if ingredientsSetter then
                        ingredientsSetter(newRecipe, difficultyTag, ingredientsPermutations[i])
                    end
                    if resultsSetter then
                        resultsSetter(newRecipe, difficultyTag, resultsPermutations[j])
                    end
                    newRecipe.name = functions.generateRecipeName(recipe.name, RECIPE_AFFIX, difficultyTag, i, j)
                    newRecipies[#newRecipies + 1] = newRecipe
                end
            end
        end
    end
    return newRecipies
end

local function generateLocalisation(recipe)
    local newRecipeLocalisedName
    if recipe.localised_name then
        newRecipeLocalisedName = recipe.localised_name
    else
        if recipe.normal then
            if recipe.normal.results then
                if #recipe.normal.results == 1 then
                    if recipe.normal.results[1].type == "fluid" then
                        newRecipeLocalisedName = {"fluid-name."..recipe.normal.results[1].name}
                    else
                        newRecipeLocalisedName = {"item-name."..recipe.normal.results[1].name}
                    end
                elseif recipe.normal.main_product or recipe.main_product then
                    local resultType
                    local lookingFor = recipe.normal.main_product or recipe.main_product
                    for i = 1, #recipe.normal.results do
                        if recipe.normal.results[i].name == lookingFor then
                            resultType = recipe.normal.results[i].type
                            break
                        end
                    end
                    if resultType then
                        newRecipeLocalisedName = {resultType.."-name."..lookingFor}
                    end
                end
            end
        else
            if recipe.results then
                if #recipe.results == 1 then
                    if recipe.results[1].type == "fluid" then
                        newRecipeLocalisedName = {"fluid-name."..recipe.results[1].name}
                    else
                        newRecipeLocalisedName = {"item-name."..recipe.results[1].name}
                    end
                elseif recipe.main_product then
                    local resultType
                    for i = 1, #recipe.results do
                        if recipe.results[i].name == recipe.main_product then
                            resultType = recipe.results[i].type
                            break
                        end
                    end
                    if resultType then
                        newRecipeLocalisedName = {resultType.."-name."..recipe.main_product}
                    end
                end
            elseif recipe.result then
                newRecipeLocalisedName = {"item-name."..recipe.result}
            end
        end
        if newRecipeLocalisedName == nil then
            newRecipeLocalisedName = {"recipe-name."..recipe.name}
        end
    end
    return newRecipeLocalisedName
end

local function generateRecipies()
    local affectedRecipies = 0
    local newRecipiesCount = 0

    local newSubgroups = {}
    local newRecipies = {}
    local newRecipeNames = {}
    for _,recipe in pairs(data.raw.recipe) do
        local status, permutations = pcall(generateRecipePermutations, recipe)
        if not status then
            log("Error while generating permutations for recipe: "..serpent.block(recipe))
            error(permutations)
        end

        if #permutations > 0 then
            local subgroupName
            local subgroupOrder
            if recipe.subgroup then
                subgroupName = recipe.category.."-"..recipe.subgroup.."-"..recipe.name.."-perm";
                subgroupOrder = data.raw["item-subgroup"][recipe.subgroup].order
            else
                subgroupName = recipe.category.."-"..recipe.name.."-perm";
                subgroupOrder = nil
            end

            newSubgroups[#newSubgroups + 1] = {
                type = "item-subgroup",
                name = subgroupName,
                group = ITEM_GROUP_NAME,
                order = subgroupOrder,
            }
            local newRecipeLocalisedName = generateLocalisation(recipe)

            newRecipeNames[recipe.name] = {}
            for i = 1, #permutations do
                permutations[i].subgroup = subgroupName
                permutations[i].localised_name = newRecipeLocalisedName
                permutations[i].hidden = true
                if permutations[i].normal then
                    permutations[i].normal.hidden = true
                end
                if permutations[i].expensive then
                    permutations[i].expensive.hidden = true
                end

                newRecipeNames[recipe.name][#newRecipeNames[recipe.name] + 1] = permutations[i].name
            end

            newRecipies[#newRecipies + 1] = permutations

            affectedRecipies = affectedRecipies + 1
            newRecipiesCount = newRecipiesCount + #permutations
        end
    end

    log("Affected recipes count: "..affectedRecipies)
    log("New recipes count: "..newRecipiesCount)

    if #newSubgroups > 0 then
        data:extend(newSubgroups)
    end
    if #newRecipies > 0 then
        for i = 1, #newRecipies do
            data:extend(newRecipies[i])
        end
    end

    for _, moduleItem in pairs(data.raw.module) do
        if moduleItem.limitation then
            local newRestrictions = {}
            for j = #moduleItem.limitation, 1, -1 do
                local restriction = moduleItem.limitation[j]
                if newRecipeNames[restriction] then
                    for i = 1, #newRecipeNames[restriction] do
                        moduleItem.limitation[#moduleItem.limitation + 1] = newRecipeNames[restriction][i]
                    end
                end
            end
        end
    end
end

generateRecipies()
