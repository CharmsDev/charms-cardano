package validator

import scalus.*
import scalus.builtin.Data
import scalus.builtin.ByteString.hex
import scalus.ledger.api.v3.{PubKeyHash, TxInfo, TxOutRef}
import scalus.prelude.*
import scalus.prelude.Option.Some
import scalus.prelude.Prelude.*
import scalus.ledger.api.v3.CurrencySymbol

val IPC_PubKeyHash = PubKeyHash(
          hex"1234567890abcdef1234567890abcdef1234567890abcdef12345678"
        ) // Replace with actual PubKeyHash


/** This validator demonstrates one key validation check:
    * 1. It verifies that the transaction is signed by the owner's public key hash (above)
    * 
    * This condition must be met for the validator to approve spending the UTxO.
      */

@Compile
object CharmsScrolls extends Validator:
    override def spend(
        datum: Option[Data],
        redeemer: Data,
        tx: TxInfo,
        outRef: TxOutRef
    ): Unit =
        val signed = tx.signatories.contains(IPC_PubKeyHash)
        require(signed, "Must be signed")

    override def mint(redeemer: Data, currencySymbol: CurrencySymbol, tx: TxInfo): Unit = 
        //if (tx.mint.isPositive) { // TODO - figure out why this doesn't compile
            val signed = tx.signatories.contains(IPC_PubKeyHash)
            require(signed, "Must be signed")
        //}
