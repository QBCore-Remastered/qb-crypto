local Translations = {
    error = {
        you_dont_have_a_cryptostick = 'Du hast keinen Cryptostick',
        one_bus_active = 'Du kannst nur einen aktiven Bus zur gleichen Zeit haben',
        drop_off_passengers = 'Lass die Fahrgäste aussteigen, bevor du aufhörst zu arbeiten',
        cryptostick_malfunctioned = 'Cryptostick funktioniert nicht richtig'
    },
    success = {
        you_have_exchanged_your_cryptostick_for = 'Du hast deinen Cryptostick gegen %{amount} QBit(s) eingetauscht'
    },
    credit = {
        there_are_amount_credited = 'Es sind %{amount} Qbit(s) gutgeschrieben!',
        you_have_qbit_purchased = 'Du hast %{dataCoins} Qbit(s) gekauft!'
    },
    depreciation = {
        you_have_sold = 'Du hast %{dataCoins} Qbit(s) verkauft!'
    },
    text = {
        enter_usb = '[E] - USB betreten',
        system_is_rebooting = 'System wird neu gestartet - %{rebootInfoPercentage} %',
        you_have_not_given_a_new_value = 'Du hast keinen neuen Wert angegeben.. Aktuelle Werte: %{crypto}',
        this_crypto_does_not_exist = 'Diese Kryptowährung existiert nicht :(, verfügbar: Qbit',
        you_have_not_provided_crypto_available_qbit = 'Du hast keine Kryptowährung angegeben, verfügbar: Qbit',
        the_qbit_has_a_value_of = 'Das Qbit hat einen Wert von: %{crypto}',
        you_have_with_a_value_of = 'Du hast: %{playerPlayerDataMoneyCrypto} QBit, mit einem Wert von: %{mypocket},-'
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