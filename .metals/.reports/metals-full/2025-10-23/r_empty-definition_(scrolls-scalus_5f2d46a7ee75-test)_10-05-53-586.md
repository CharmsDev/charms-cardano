error id: file:///C:/Users/Sam/Ikigai/charms-cardano/scrolls-scalus/Scrolls.test.scala:`<none>`.
file:///C:/Users/Sam/Ikigai/charms-cardano/scrolls-scalus/Scrolls.test.scala
empty definition using pc, found symbol in pc: `<none>`.
empty definition using semanticdb
empty definition using fallback
non-local guesses:
	 -scalus/Scrolls.
	 -scalus/builtin/ByteString.Scrolls.
	 -scalus/prelude/Scrolls.
	 -scalus/uplc/Scrolls.
	 -scalus/uplc/eval/Scrolls.
	 -scala/math/Ordering.Implicits.Scrolls.
	 -Scrolls.
	 -scala/Predef.Scrolls.
offset: 900
uri: file:///C:/Users/Sam/Ikigai/charms-cardano/scrolls-scalus/Scrolls.test.scala
text:
```scala
package validator

import munit.FunSuite
import scalus.*
import scalus.Compiler.compile
import scalus.builtin.ByteString.*
import scalus.builtin.Data.toData
import scalus.builtin.{ByteString, Data}
import scalus.ledger.api.v1.PubKeyHash
import scalus.prelude.*
import scalus.testkit.ScalusTest
import scalus.uplc.*
import scalus.uplc.eval.*

import scala.language.implicitConversions
import scala.math.Ordering.Implicits.*

class ScrollsSpec extends FunSuite, ScalusTest {

    test("Scrolls validator passes with correct signature") {
        val IPC_PubKeyHash = PubKeyHash(
          hex"1234567890abcdef1234567890abcdef1234567890abcdef12345678"
        )
        val context = makeSpendingScriptContext(
          datum = IPC_PubKeyHash.toData,
          redeemer = message,
          signatories = List(IPC_PubKeyHash)
        )

        val result = compile(Scrolls@@.validate).runScript(context)

        assert(result.isSuccess)
        assert(result.budget <= ExBudget(ExCPU(62000000), ExMemory(240000)))
    }
}

```


#### Short summary: 

empty definition using pc, found symbol in pc: `<none>`.