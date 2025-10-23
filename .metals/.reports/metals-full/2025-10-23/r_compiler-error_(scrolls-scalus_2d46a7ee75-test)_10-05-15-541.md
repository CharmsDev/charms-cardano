jar:file:///C:/Users/Sam/AppData/Local/Coursier/cache/v1/https/repo1.maven.org/maven2/org/scalus/scalus-testkit_3/0.10.1/scalus-testkit_3-0.10.1-sources.jar!/scalus/testkit/ScalusTest.scala
### java.lang.AssertionError: assertion failed

occurred in the presentation compiler.

presentation compiler configuration:


action parameters:
uri: jar:file:///C:/Users/Sam/AppData/Local/Coursier/cache/v1/https/repo1.maven.org/maven2/org/scalus/scalus-testkit_3/0.10.1/scalus-testkit_3-0.10.1-sources.jar!/scalus/testkit/ScalusTest.scala
text:
```scala
package scalus.testkit

import org.scalacheck.{Arbitrary, Gen}
import scalus.*
import scalus.builtin.Data.toData
import scalus.builtin.{ByteString, Data, given}
import scalus.builtin.Builtins.blake2b_224
import scalus.ledger.api.v1.PubKeyHash
import scalus.ledger.api.v1.Credential.{PubKeyCredential, ScriptCredential}
import scalus.ledger.api.v3.*
import scalus.prelude.*
import scalus.sir.SIR
import scalus.uplc.*
import scalus.uplc.eval.*

trait ScalusTest {
    protected given PlutusVM = PlutusVM.makePlutusV3VM()

    extension (self: SIR)
        def runScript(scriptContext: ScriptContext): Result =
            // UPLC program: (ScriptContext as Data) -> ()
            val script = self.toUplc(generateErrorTraces = true).plutusV3
            val appliedScript = script $ scriptContext.toData
            appliedScript.evaluateDebug

        def scriptV3(errorTraces: Boolean = true): Program =
            self.toUplc(generateErrorTraces = errorTraces).plutusV3

    extension (self: Program)
        def runWithDebug(scriptContext: ScriptContext): Result =
            val appliedScript = self $ scriptContext.toData
            appliedScript.evaluateDebug

        def hash: ValidatorHash = blake2b_224(ByteString.fromArray(3 +: self.cborEncoded))

    protected def genByteStringOfN(n: Int): Gen[ByteString] = {
        Gen
            .containerOfN[Array, Byte](n, Arbitrary.arbitrary[Byte])
            .map(a => ByteString.unsafeFromArray(a))
    }

    given Arbitrary[TxId] = Arbitrary(genByteStringOfN(32).map(TxId.apply))
    given Arbitrary[TxOutRef] = Arbitrary {
        for
            txId <- Arbitrary.arbitrary[TxId]
            index <- Gen.choose(0, 1000)
        yield TxOutRef(txId, index)
    }

    protected def random[A: Arbitrary]: A = {
        Arbitrary.arbitrary[A].sample.get
    }

    protected def makeSpendingScriptContext(
        datum: Data,
        redeemer: Redeemer,
        signatories: List[PubKeyHash]
    ): ScriptContext = {
        val ownInput =
            TxInInfo(
              outRef = Arbitrary.arbitrary[TxOutRef].sample.get,
              resolved = TxOut(
                address = Address(
                  Credential.ScriptCredential(genByteStringOfN(28).sample.get),
                  Option.None
                ),
                value = Value.zero
              )
            )
        ScriptContext(
          txInfo = TxInfo(
            inputs = List(ownInput),
            fee = 188021,
            signatories = signatories,
            id = random[TxId]
          ),
          redeemer = redeemer,
          scriptInfo = ScriptInfo.SpendingScript(
            txOutRef = ownInput.outRef,
            datum = Option.Some(datum)
          )
        )
    }

    protected def makePubKeyHashInput(pkh: Hash, value: BigInt): TxInInfo = {
        TxInInfo(
          outRef = TxOutRef(random[TxId], 0),
          resolved = TxOut(
            address = Address(PubKeyCredential(PubKeyHash(pkh)), Option.None),
            value = Value.lovelace(value)
          )
        )
    }

    protected def makeScriptHashInput(scriptHash: ValidatorHash, value: BigInt): TxInInfo = {
        TxInInfo(
          outRef = TxOutRef(random[TxId], 0),
          resolved = TxOut(
            address = Address(ScriptCredential(scriptHash), Option.None),
            value = Value.lovelace(value)
          )
        )
    }

    protected def makePubKeyHashOutput(pkh: Hash, value: BigInt): TxOut = {
        TxOut(
          address = Address(PubKeyCredential(PubKeyHash(pkh)), Option.None),
          value = Value.lovelace(value)
        )
    }

    protected def makeScriptHashOutput(scriptHash: ValidatorHash, value: BigInt): TxOut = {
        TxOut(
          address = Address(ScriptCredential(scriptHash), Option.None),
          value = Value.lovelace(value)
        )
    }

    final protected def failure(message: String): (String, Option[ExBudget]) =
        (message, Option.None)
    final protected def failure(message: String, budget: ExBudget): (String, Option[ExBudget]) =
        (message, Option.Some(budget))
    protected val success: (Unit, Option[ExBudget]) = ((), Option.None)
    final protected def success(budget: ExBudget): (Unit, Option[ExBudget]) =
        ((), Option.Some(budget))

    protected def checkResult(
        expected: (String | Unit, Option[ExBudget]),
        actual: Result
    ): Unit = {
        expected._1 match
            case errorMsg: String =>
                assert(
                  actual.isFailure,
                  s"Expected failure with: $errorMsg, but got success"
                )
                // If a specific error message is provided, check it matches
                assert(
                  actual.logs.exists(_.contains(errorMsg)),
                  s"Expected error containing: $errorMsg, but got: ${actual.logs.mkString(", ")}"
                )
            case () =>
                actual match
                    case Result.Failure(ex, budget, cost, logs) =>
                        ex match
                            case be: scalus.uplc.eval.BuiltinError =>
                                be.cause.printStackTrace()
                            case _ =>
                    case _ =>
                assert(
                  actual.isSuccess,
                  s"Expected success, but got: ${actual.toString}, logs0: ${actual.logs.mkString(", ")}"
                )

        expected._2 match
            case Option.Some(budget) if budget != ExBudget(ExCPU(0), ExMemory(0)) =>
                assert(
                  actual.budget == budget,
                  s"Expected budget: $budget, but got: ${actual.budget}"
                )
            case _ =>
    }

    def compareBudgetWithReferenceValue(
        testName: String,
        scalusBudget: ExBudget,
        refBudget: ExBudget,
        isPrintComparison: Boolean = false
    ): Unit = {
        import ScalusTest.BenchmarkConfig
        extension (scalus: Long)
            def comparisonAsJsonString(ref: Long): String = {
                val comparison = f"${scalus.toDouble / ref.toDouble * 100}%.2f"
                s"{scalus: $scalus, ref: $ref, comparison: $comparison%}"
            }

        end extension

        if isPrintComparison || BenchmarkConfig.isPrintAllComparisonsOfBudgetWithReferenceValue then
            println(
              s"${BenchmarkConfig.logPrefix}[$testName]: {" +
                  s"cpu: ${scalusBudget.cpu.comparisonAsJsonString(refBudget.cpu)}, " +
                  s"memory: ${scalusBudget.memory.comparisonAsJsonString(refBudget.memory)}" +
                  "}"
            )
    }
}

object ScalusTest {
    private object BenchmarkConfig {
        inline val logPrefix = "BenchmarkComparison"
        val isPrintAllComparisonsOfBudgetWithReferenceValue: Boolean = false
    }
}

```



#### Error stacktrace:

```
scala.runtime.Scala3RunTime$.assertFailed(Scala3RunTime.scala:11)
	dotty.tools.dotc.core.TypeOps$.dominators$1(TypeOps.scala:251)
	dotty.tools.dotc.core.TypeOps$.approximateOr$1(TypeOps.scala:387)
	dotty.tools.dotc.core.TypeOps$.orDominator(TypeOps.scala:400)
	dotty.tools.dotc.core.Types$OrType.join(Types.scala:3502)
	dotty.tools.dotc.core.Types$Type.classSymbol(Types.scala:574)
	dotty.tools.dotc.typer.Typer.checkEqualityEvidence(Typer.scala:4513)
	dotty.tools.dotc.typer.Typer.adaptNoArgsOther$1(Typer.scala:4089)
	dotty.tools.dotc.typer.Typer.adaptNoArgs$1(Typer.scala:4201)
	dotty.tools.dotc.typer.Typer.adapt1(Typer.scala:4455)
	dotty.tools.dotc.typer.Typer.adapt(Typer.scala:3704)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3302)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3306)
	dotty.tools.dotc.typer.Typer.typedTuple(Typer.scala:3060)
	dotty.tools.dotc.typer.Typer.typedUnnamed$1(Typer.scala:3188)
	dotty.tools.dotc.typer.Typer.typedUnadapted(Typer.scala:3232)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3302)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3306)
	dotty.tools.dotc.typer.Typer.typedPattern(Typer.scala:3437)
	dotty.tools.dotc.typer.Typer.typedCase(Typer.scala:1960)
	dotty.tools.dotc.typer.Typer.typedCases$$anonfun$1(Typer.scala:1886)
	dotty.tools.dotc.core.Decorators$.loop$1(Decorators.scala:94)
	dotty.tools.dotc.core.Decorators$.mapconserve(Decorators.scala:110)
	dotty.tools.dotc.typer.Typer.typedCases(Typer.scala:1885)
	dotty.tools.dotc.typer.Typer.$anonfun$34(Typer.scala:1870)
	dotty.tools.dotc.typer.Applications.harmonic(Applications.scala:2444)
	dotty.tools.dotc.typer.Applications.harmonic$(Applications.scala:400)
	dotty.tools.dotc.typer.Typer.harmonic(Typer.scala:119)
	dotty.tools.dotc.typer.Typer.typedMatchFinish(Typer.scala:1870)
	dotty.tools.dotc.typer.Typer.typedMatch(Typer.scala:1803)
	dotty.tools.dotc.typer.Typer.typedUnnamed$1(Typer.scala:3165)
	dotty.tools.dotc.typer.Typer.typedUnadapted(Typer.scala:3232)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3302)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3306)
	dotty.tools.dotc.typer.Typer.traverse$1(Typer.scala:3355)
	dotty.tools.dotc.typer.Typer.typedStats(Typer.scala:3374)
	dotty.tools.dotc.typer.Typer.typedBlockStats(Typer.scala:1223)
	dotty.tools.dotc.typer.Typer.typedBlock(Typer.scala:1227)
	dotty.tools.dotc.typer.Typer.typedUnnamed$1(Typer.scala:3159)
	dotty.tools.dotc.typer.Typer.typedUnadapted(Typer.scala:3232)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3302)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3306)
	dotty.tools.dotc.typer.Typer.typedExpr(Typer.scala:3417)
	dotty.tools.dotc.typer.Typer.$anonfun$58(Typer.scala:2584)
	dotty.tools.dotc.inlines.PrepareInlineable$.dropInlineIfError(PrepareInlineable.scala:242)
	dotty.tools.dotc.typer.Typer.typedDefDef(Typer.scala:2584)
	dotty.tools.dotc.typer.Typer.typedNamed$1(Typer.scala:3127)
	dotty.tools.dotc.typer.Typer.typedUnadapted(Typer.scala:3231)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3302)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3306)
	dotty.tools.dotc.typer.Typer.traverse$1(Typer.scala:3328)
	dotty.tools.dotc.typer.Typer.typedStats(Typer.scala:3374)
	dotty.tools.dotc.typer.Typer.typedClassDef(Typer.scala:2771)
	dotty.tools.dotc.typer.Typer.typedTypeOrClassDef$1(Typer.scala:3139)
	dotty.tools.dotc.typer.Typer.typedNamed$1(Typer.scala:3143)
	dotty.tools.dotc.typer.Typer.typedUnadapted(Typer.scala:3231)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3302)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3306)
	dotty.tools.dotc.typer.Typer.traverse$1(Typer.scala:3328)
	dotty.tools.dotc.typer.Typer.typedStats(Typer.scala:3374)
	dotty.tools.dotc.typer.Typer.typedPackageDef(Typer.scala:2914)
	dotty.tools.dotc.typer.Typer.typedUnnamed$1(Typer.scala:3184)
	dotty.tools.dotc.typer.Typer.typedUnadapted(Typer.scala:3232)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3302)
	dotty.tools.dotc.typer.Typer.typed(Typer.scala:3306)
	dotty.tools.dotc.typer.Typer.typedExpr(Typer.scala:3417)
	dotty.tools.dotc.typer.TyperPhase.typeCheck$$anonfun$1(TyperPhase.scala:45)
	scala.runtime.function.JProcedure1.apply(JProcedure1.java:15)
	scala.runtime.function.JProcedure1.apply(JProcedure1.java:10)
	dotty.tools.dotc.core.Phases$Phase.monitor(Phases.scala:467)
	dotty.tools.dotc.typer.TyperPhase.typeCheck(TyperPhase.scala:51)
	dotty.tools.dotc.typer.TyperPhase.$anonfun$4(TyperPhase.scala:97)
	scala.collection.Iterator$$anon$6.hasNext(Iterator.scala:479)
	scala.collection.Iterator$$anon$9.hasNext(Iterator.scala:583)
	scala.collection.immutable.List.prependedAll(List.scala:152)
	scala.collection.immutable.List$.from(List.scala:685)
	scala.collection.immutable.List$.from(List.scala:682)
	scala.collection.IterableOps$WithFilter.map(Iterable.scala:900)
	dotty.tools.dotc.typer.TyperPhase.runOn(TyperPhase.scala:96)
	dotty.tools.dotc.Run.runPhases$1$$anonfun$1(Run.scala:315)
	scala.runtime.function.JProcedure1.apply(JProcedure1.java:15)
	scala.runtime.function.JProcedure1.apply(JProcedure1.java:10)
	scala.collection.ArrayOps$.foreach$extension(ArrayOps.scala:1324)
	dotty.tools.dotc.Run.runPhases$1(Run.scala:308)
	dotty.tools.dotc.Run.compileUnits$$anonfun$1(Run.scala:348)
	dotty.tools.dotc.Run.compileUnits$$anonfun$adapted$1(Run.scala:357)
	dotty.tools.dotc.util.Stats$.maybeMonitored(Stats.scala:69)
	dotty.tools.dotc.Run.compileUnits(Run.scala:357)
	dotty.tools.dotc.Run.compileSources(Run.scala:261)
	dotty.tools.dotc.interactive.InteractiveDriver.run(InteractiveDriver.scala:161)
	dotty.tools.pc.CachingDriver.run(CachingDriver.scala:45)
	dotty.tools.pc.SemanticdbTextDocumentProvider.textDocument(SemanticdbTextDocumentProvider.scala:32)
	dotty.tools.pc.ScalaPresentationCompiler.semanticdbTextDocument$$anonfun$1(ScalaPresentationCompiler.scala:242)
```
#### Short summary: 

java.lang.AssertionError: assertion failed