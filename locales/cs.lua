local Translations = {
    error = {
        you_dont_have_a_cryptostick = 'Nemáte kryptostick',
        one_bus_active = 'Můžete mít pouze jeden aktivní autobus najednou',
        drop_off_passengers = 'Vysaďte cestující před tím, než přestanete pracovat',
        cryptostick_malfunctioned = 'Kryptostick selhal'
    },
    success = {
        you_have_exchanged_your_cryptostick_for = 'Vyměnili jste svůj kryptostick za: %{amount} QBit(s)'
    },
    credit = {
        there_are_amount_credited = 'Je zapsáno %{amount} Qbit(s)!',
        you_have_qbit_purchased = 'Zakoupili jste %{dataCoins} Qbit(s)!'
    },
    depreciation = {
        you_have_sold = 'Prodali jste %{dataCoins} Qbit(s)!'
    },
    text = {
        enter_usb = '[E] - Vložit USB',
        system_is_rebooting = 'Systém se restartuje - %{rebootInfoPercentage} %',
        you_have_not_given_a_new_value = 'Nedali jste novou hodnotu... Aktuální hodnoty: %{crypto}',
        this_crypto_does_not_exist = 'Tato kryptoměna neexistuje :(, dostupná: Qbit',
        you_have_not_provided_crypto_available_qbit = 'Neposkytli jste kryptoměnu, dostupná: Qbit',
        the_qbit_has_a_value_of = 'Qbit má hodnotu: %{crypto}',
        you_have_with_a_value_of = 'Máte: %{playerPlayerDataMoneyCrypto} QBit, s hodnotou: %{mypocket},-'
    }
}

if GetConvar('qb_locale', 'en') == 'cs' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
--translate by stepan_valic