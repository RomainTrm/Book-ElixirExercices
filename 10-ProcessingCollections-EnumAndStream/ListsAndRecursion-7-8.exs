defmodule MyList do

    def span(from, to) do
        Enum.to_list from..to
    end

    # Exercice 7
    def primeNumbers(n) do
        for number <- 2..n,
            2..n
            |> Enum.to_list
            |> Enum.filter(&(&1 != number))
            |> Enum.all?(&(rem(number,&1) != 0)),
            do: number
    end

    # Exercice 8
     def applyTaxe(ship_to, net_amount) do
        tax_rates = [ NC: 0.075, TX: 0.08 ]
        if tax_rates[ship_to] == nil do
            net_amount
        else
            net_amount * (1.0 + tax_rates[ship_to])
        end
    end

    def applyTaxes(orders) do
        orders
        |> Enum.map (fn order ->
            total_amount = applyTaxe(order[:ship_to], order[:net_amount])
            order++[total_amount: total_amount]
            end)
    end

    def runApplyTaxes do
        applyTaxes [
            [id: 123, ship_to: :NC, net_amount: 100.00 ],
            [id: 124, ship_to: :OK, net_amount: 100.00 ],
            [id: 125, ship_to: :TX, net_amount: 100.00 ]
        ]
    end
end
